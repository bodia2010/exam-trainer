import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/voice_gender.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// One line of a dialogue/monologue: who says it and what.
class DialogueLine {
  final String speaker;
  final String text;
  final VoiceGender voiceGender;
  const DialogueLine(
    this.speaker,
    this.text, {
    this.voiceGender = VoiceGender.unknown,
  });
}

/// One ownership-aware lease for a cached TTS clip.
///
/// Every acquisition gets a distinct lease even when several callers share
/// the same on-disk [path]. [release] is idempotent for this specific owner,
/// so calling it twice can never consume another caller's protection.
class TtsAudioLease {
  TtsAudioLease._(this.path, this._releaseCallback);

  final String path;
  final Future<void> Function() _releaseCallback;
  Future<void>? _releaseFuture;

  Future<void> release() => _releaseFuture ??= _releaseCallback();
}

/// Lazily synthesizes German dialogue audio via the backend's Microsoft
/// Edge TTS endpoint (/api/tts) and caches the result on disk, so a given
/// line is only ever synthesized once across app restarts.
class TtsService {
  TtsService._();
  static final instance = TtsService._();
  // edge-tts paces long requests close to real-time speech; 400-char
  // chunks measured around 8s, but leave real margin for network jitter.
  static const _timeout = Duration(seconds: 45);

  Directory? _cacheDir;

  /// Clears the memoized cache directory so a test that swaps
  /// `PathProviderPlatform.instance` between runs doesn't keep resolving
  /// to a previous test's temp directory. Also drops any tracked in-flight
  /// operations so a previous test's (already-settled) futures can't be
  /// mistaken for a pending operation belonging to the next test.
  @visibleForTesting
  void debugResetCacheDirForTests() {
    _cacheDir = null;
    _pendingByKey.clear();
    _cacheTransactionChain = Future.value();
    _legacyCleanupDone = false;
    _pinnedPaths.clear();
    _activeLeases.clear();
    _nextLeaseId = 0;
  }

  /// Read-only view of the current pin refcounts, keyed by path. Exposed
  /// only so tests can assert precisely that a
  /// lease was actually released (refcount gone) rather than merely
  /// "probably fine", including distinguishing "released then re-pinned"
  /// (count back to 1) from "never released" (count still accumulating).
  @visibleForTesting
  Map<String, int> get debugPinCountsForTests => Map.unmodifiable(_pinnedPaths);

  /// CR-14: the OS cache directory rather than the app's persistent
  /// Documents directory — this audio is always re-derivable from the
  /// course text via [_synthesize], so it's safe for the OS to evict
  /// under storage pressure and doesn't belong in `allowBackup`-style
  /// backups (see CR-12) or count against the app's "data" storage the
  /// user sees in system settings.
  Future<Directory> get _dir async {
    if (_cacheDir != null) return _cacheDir!;
    await _cleanupLegacyCacheOnce();
    final base = await getApplicationCacheDirectory();
    final d = Directory('${base.path}/tts_cache');
    if (!d.existsSync()) d.createSync(recursive: true);
    return _cacheDir = d;
  }

  bool _legacyCleanupDone = false;

  /// Lets a test simulate a storage exception during legacy cleanup
  /// deterministically, without depending on platform-specific filesystem
  /// permission quirks.
  @visibleForTesting
  static bool debugForceLegacyCleanupFailure = false;

  /// Before CR-14, cached audio lived in the app's persistent
  /// `Documents/tts_cache` — unbounded and never evicted. Devices that
  /// upgrade from that build are left with an orphaned directory that
  /// nothing reads or trims anymore. This is a one-time (per process),
  /// best-effort removal: the directory holds only re-derivable TTS clips
  /// ([_synthesize] regenerates anything missing), so there is nothing to
  /// preserve, and a failure here (permissions, a concurrent process, a
  /// missing directory) must never block a real TTS request — it's simply
  /// retried on the next launch since [_legacyCleanupDone] is in-memory
  /// only.
  Future<void> _cleanupLegacyCacheOnce() async {
    if (_legacyCleanupDone) return;
    _legacyCleanupDone = true;
    try {
      if (debugForceLegacyCleanupFailure) {
        throw const FileSystemException('simulated legacy cleanup failure');
      }
      final docs = await getApplicationDocumentsDirectory();
      // Exact former cache path — never anything broader than this single,
      // TTS-exclusive subdirectory of Documents.
      final legacy = Directory('${docs.path}/tts_cache');
      if (await legacy.exists()) {
        await legacy.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort: never let cleanup break audio playback.
    }
  }

  /// Bounds how much disk space cached clips can hold in total — without
  /// this, importing many courses and playing through all their audio
  /// grows this directory forever. 200 MB is generous for MP3 speech clips
  /// (a few hundred short lines) while still being a real cap.
  static const _maxCacheBytes = 200 * 1024 * 1024;

  /// Trims back to 90% of the cap rather than exactly 100% so a single
  /// eviction pass doesn't immediately re-trigger on the very next write.
  static const _cacheTrimTargetRatio = 0.9;

  /// Lets tests exercise eviction with a handful of small fake clips
  /// instead of writing 200 MB of real audio.
  @visibleForTesting
  static int? debugMaxCacheBytesOverride;

  int get _cacheBudget => debugMaxCacheBytesOverride ?? _maxCacheBytes;

  /// Test seam for stubbing the TTS HTTP call. `null` (the default,
  /// untouched in production) means "use the shared production client".
  @visibleForTesting
  static http.Client? debugHttpClient;

  final http.Client _productionHttpClient = http.Client();
  http.Client get _httpClient => debugHttpClient ?? _productionHttpClient;

  /// Test seam standing in for [AuthService.requireIdToken] — a plain unit
  /// test has no real signed-in Firebase user/app. `null` (the default,
  /// untouched in production) means "use the real Firebase ID token".
  @visibleForTesting
  static Future<String> Function()? debugIdTokenOverride;

  // edge-tts doesn't synthesize much faster than real-time speech once a
  // request gets long (measured: ~8s for 350 chars, ~25s for 900, ~37s for
  // 1800) — so a bigger chunk just means a slower, timeout-prone request,
  // not fewer of them. Keep chunks short and reliable; a Telefonnotiz
  // monologue ends up as a handful of clips with a brief gap rather than
  // one clip that risks timing out.
  static const _maxCharsPerRequest = 400;

  /// A new speaker turn starts either at the very start of the text, or
  /// right after the previous turn's sentence-ending punctuation — never
  /// mid-sentence, which is what keeps this from mistaking an incidental
  /// colon (a quoted phrase like "... mit dem Begriff: „Wunschzeit
  /// gebucht"") for a new speaker. The name itself is 1-2 words (plain
  /// names, "Herr"/"Frau" + surname, or telc's anonymized "Frau 1" /
  /// "Frau 2" / "Herr " labels — the trailing space before the colon on
  /// an unnumbered "Herr :" is deliberate source formatting to line up
  /// with the numbered labels, so the colon isn't required to hug the
  /// name), followed by ":" and a space.
  static final _turnStartPattern = RegExp(
    r'(?:^|(?<=[.!?…])\s+)([A-ZÄÖÜ][\wäöüß]*(?:\s[A-ZÄÖÜ0-9][\w0-9äöüß]*)?)\s*:\s+',
  );

  /// Splits "Speaker: text" formatted dialogue into lines. Text with no
  /// such prefixes (a plain monologue) becomes one or more sentence-sized
  /// lines, kept under [_maxCharsPerRequest] each.
  ///
  /// Turn boundaries are found by scanning the WHOLE text for
  /// [_turnStartPattern], not by first splitting on '\n' — the source PDF
  /// hard-wraps and hyphenates lines mid-sentence, and depending on how
  /// Gemini reproduced the layout, multiple speaker turns sometimes land
  /// on the same raw line with no '\n' between them at all. A per-line
  /// regex (the previous approach) would then greedily swallow every
  /// later turn into the first speaker's text — confirmed live: a whole
  /// Hören Teil 1 exchange (Chef/Zarif alternating four times) collapsed
  /// into one oversized "Chef" line, with wrong audio to match. Scanning
  /// globally finds every turn regardless of the source's line breaks;
  /// '\n' inside a turn (a genuine hard-wrap, not a new speaker) is just
  /// collapsed to a space, joining hyphenated word-splits ("ge-" +
  /// "stalten") with no space and everything else with one — the same
  /// join rule the old per-line version used, just applied uniformly.
  List<DialogueLine> parseLines(
    String text, {
    VoiceGender parsedVoiceGender = VoiceGender.unknown,
    Map<String, VoiceGender> parsedSpeakerVoiceGenders = const {},
    VoiceGender? manualVoiceGenderOverride,
    Map<String, VoiceGender> manualSpeakerVoiceGenderOverrides = const {},
  }) {
    final normalized = text
        .replaceAll(RegExp(r'-\n\s*'), '')
        .replaceAll('\n', ' ')
        .trim();
    if (normalized.isEmpty) return const [];

    final matches = _turnStartPattern.allMatches(normalized).toList();
    final lines = <DialogueLine>[];
    if (matches.isEmpty) {
      lines.add(
        _lineWithResolvedGender(
          '',
          normalized,
          parsedVoiceGender,
          parsedSpeakerVoiceGenders,
          manualVoiceGenderOverride,
          manualSpeakerVoiceGenderOverrides,
        ),
      );
    } else {
      for (var i = 0; i < matches.length; i++) {
        final m = matches[i];
        final end = i + 1 < matches.length
            ? matches[i + 1].start
            : normalized.length;
        final turnText = normalized.substring(m.end, end).trim();
        if (turnText.isEmpty) continue;
        lines.add(
          _lineWithResolvedGender(
            m.group(1)!.trim(),
            turnText,
            parsedVoiceGender,
            parsedSpeakerVoiceGenders,
            manualVoiceGenderOverride,
            manualSpeakerVoiceGenderOverrides,
          ),
        );
      }
      // Text before the first recognized turn (or a document with no
      // recognizable speaker pattern at all) — keep it rather than
      // silently drop it.
      if (matches.first.start > 0) {
        final lead = normalized.substring(0, matches.first.start).trim();
        if (lead.isNotEmpty) {
          lines.insert(
            0,
            _lineWithResolvedGender(
              '',
              lead,
              parsedVoiceGender,
              parsedSpeakerVoiceGenders,
              manualVoiceGenderOverride,
              manualSpeakerVoiceGenderOverrides,
            ),
          );
        }
      }
    }

    // A monologue (Telefonnotiz, Hören Teil 2-4 announcements) has no
    // "Speaker:" turns, so every line above landed with an empty speaker.
    // Keep narrator self-introductions as speaker identity only; gender is
    // resolved separately from manual override, parser hint, or Frau/Herr.
    if (lines.isNotEmpty && lines.every((l) => l.speaker.isEmpty)) {
      final narrator = _detectNarrator(text);
      if (narrator != null) {
        for (var i = 0; i < lines.length; i++) {
          lines[i] = _lineWithResolvedGender(
            narrator,
            lines[i].text,
            parsedVoiceGender,
            parsedSpeakerVoiceGenders,
            manualVoiceGenderOverride,
            manualSpeakerVoiceGenderOverrides,
          );
        }
      }
    }

    return lines.expand(_splitIfTooLong).toList();
  }

  DialogueLine _lineWithResolvedGender(
    String speaker,
    String text,
    VoiceGender parsedVoiceGender,
    Map<String, VoiceGender> parsedSpeakerVoiceGenders,
    VoiceGender? manualVoiceGenderOverride,
    Map<String, VoiceGender> manualSpeakerVoiceGenderOverrides,
  ) => DialogueLine(
    speaker,
    text,
    voiceGender: VoiceGender.resolve(
      manualOverride:
          _genderForSpeaker(manualSpeakerVoiceGenderOverrides, speaker) ??
          manualVoiceGenderOverride,
      parsedHint:
          _genderForSpeaker(parsedSpeakerVoiceGenders, speaker) ??
          parsedVoiceGender,
      speaker: speaker,
    ),
  );

  VoiceGender? _genderForSpeaker(
    Map<String, VoiceGender> genders,
    String speaker,
  ) {
    final gender = genders[VoiceGenderMetadata.speakerKey(speaker)];
    return gender == VoiceGender.unknown ? null : gender;
  }

  // Only accept a gendered name as the narrator when it appears in an
  // actual self-introduction. Searching the whole monologue is unsafe:
  // Hören Teil 4 #40 mentions "meiner Sekretärin Frau Zimmer" near the end,
  // which is a third party and not the person speaking.
  static final _narratorPattern = RegExp(
    r'^\s*(?:Hallo,?\s*)?(?:hier\s+(?:ist|spricht)|ich\s+bin|mein\s+Name\s+ist)\s+'
    r'(Herr|Frau)\s+([A-ZÄÖÜ][a-zäöüß]+)\b',
    caseSensitive: false,
  );

  static final _titledCallerPattern = RegExp(
    r'^\s*(?:Guten Tag,?\s*)?(Herr|Frau)\s+'
    r'([A-ZÄÖÜ][a-zäöüß]+)\s+am\s+Apparat\b',
    caseSensitive: false,
  );

  static final _untitledNarratorPattern = RegExp(
    r'\b(?:[Hh]ier\s+(?:ist|spricht)|[Ii]ch\s+bin|[Mm]ein\s+Name\s+ist)\s+'
    r'([A-ZÄÖÜ][a-zäöüß]+(?:\s+[A-ZÄÖÜ][a-zäöüß]+)?)\b',
  );

  /// Finds a self-introduction like "... hier spricht Frau Meier ..." or
  /// "Herr Schmitt am Apparat" so the TTS voice matches the caller's
  /// gender instead of falling back to a fixed default.
  String? _detectNarrator(String text) {
    final m = _narratorPattern.firstMatch(text);
    if (m != null) return '${m.group(1)} ${m.group(2)}';
    final caller = _titledCallerPattern.firstMatch(text);
    if (caller != null) return '${caller.group(1)} ${caller.group(2)}';
    return _untitledNarratorPattern.firstMatch(text)?.group(1);
  }

  /// Breaks one long line into several sentence-sized ones so no single
  /// TTS request exceeds the server's per-line limit.
  Iterable<DialogueLine> _splitIfTooLong(DialogueLine line) sync* {
    if (line.text.length <= _maxCharsPerRequest) {
      yield line;
      return;
    }
    final sentences = line.text.split(RegExp(r'(?<=[.!?])\s+'));
    final buffer = StringBuffer();
    for (final sentence in sentences) {
      final candidate = buffer.isEmpty
          ? sentence
          : '${buffer.toString()} $sentence';
      if (candidate.length > _maxCharsPerRequest && buffer.isNotEmpty) {
        yield DialogueLine(
          line.speaker,
          buffer.toString(),
          voiceGender: line.voiceGender,
        );
        buffer.clear();
      }
      // A single "sentence" that alone exceeds the limit (no punctuation
      // to split on) still has to be sent somehow — hard-split by words.
      if (sentence.length > _maxCharsPerRequest) {
        for (final chunk in _hardSplit(sentence, _maxCharsPerRequest)) {
          yield DialogueLine(
            line.speaker,
            chunk,
            voiceGender: line.voiceGender,
          );
        }
        continue;
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(sentence);
    }
    if (buffer.isNotEmpty) {
      yield DialogueLine(
        line.speaker,
        buffer.toString(),
        voiceGender: line.voiceGender,
      );
    }
  }

  Iterable<String> _hardSplit(String text, int maxChars) sync* {
    var start = 0;
    while (start < text.length) {
      var end = (start + maxChars).clamp(0, text.length);
      if (end < text.length) {
        final lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace > start) end = lastSpace;
      }
      yield text.substring(start, end).trim();
      start = end;
    }
  }

  VoiceGender _effectiveVoiceGender(DialogueLine line) =>
      VoiceGender.resolve(parsedHint: line.voiceGender, speaker: line.speaker);

  String _cacheKey(DialogueLine line) => sha1
      .convert(
        utf8.encode(
          'v2|${_effectiveVoiceGender(line).storageValue}|'
          '${line.speaker}|${line.text}',
        ),
      )
      .toString();

  Future<String> _cachePath(DialogueLine line) async {
    final dir = await _dir;
    return '${dir.path}/${_cacheKey(line)}.mp3';
  }

  // A genuine spoken line is always well over this many bytes; anything
  // smaller means a previous request got cut off (network hiccup, function
  // timeout) and was cached as a "valid" but silent/truncated clip.
  static const _minValidBytes = 512;

  /// Serializes all `ensureAudio` operations that target the same cache
  /// key. Without this, two concurrent calls for the same [DialogueLine]
  /// (e.g. two widgets showing the same line, or a stray double-tap) would
  /// both write to the same `<key>.mp3.tmp`: whichever renamed second hit
  /// `PathNotFoundException` because the first rename had already moved
  /// the file out from under it. Chaining onto the previous operation for
  /// this key — rather than only deduplicating identical requests — also
  /// correctly serializes a `forceRegenerate` call that arrives while a
  /// plain cache-filling call for the same key is still in flight, instead
  /// of racing it.
  final Map<String, Future<TtsAudioLease>> _pendingByKey = {};

  /// Acquires a lease for this line's local audio, synthesizing and caching
  /// it first if necessary. Pass [forceRegenerate] to ignore and overwrite
  /// whatever is already cached.
  ///
  /// [TtsAudioLease.path] is guaranteed to exist when this Future resolves
  /// and to remain protected from cache deletion until that exact lease is
  /// released. Forgetting to release leaks that lease, so every caller must
  /// release it once it's
  /// actually done using the file — see [DialogueAudioPlayer] for the
  /// reference lifecycle (prepare → play → release on completion, error,
  /// stop, regenerate, dispose, or supersession by a newer operation).
  Future<TtsAudioLease> ensureAudio(
    DialogueLine line, {
    bool forceRegenerate = false,
  }) {
    final key = _cacheKey(line);
    final previous = _pendingByKey[key];
    final operation = previous == null
        ? _ensureAudioOnce(line, forceRegenerate: forceRegenerate)
        : previous
              .then((_) {}, onError: (_) {})
              .then(
                (_) => _ensureAudioOnce(line, forceRegenerate: forceRegenerate),
              );
    _pendingByKey[key] = operation;
    // `.whenComplete()` returns its own Future that mirrors `operation`'s
    // eventual error, if any — nothing awaits that derived Future, so
    // without `.ignore()` a failed `operation` is reported as a second,
    // spurious unhandled exception even though `operation` itself (the
    // Future actually returned to callers) is properly handled by them.
    operation.whenComplete(() {
      if (identical(_pendingByKey[key], operation)) {
        _pendingByKey.remove(key);
      }
    }).ignore();
    return operation;
  }

  /// Refcounted set of paths currently leased to callers. A pinned path is
  /// protected from EVERY eviction pass,
  /// not just the pass belonging to the operation that produced it,
  /// regardless of which cache key's commit triggered that pass, until
  /// every outstanding pin on it is released. It still counts toward the
  /// cache's total size while pinned (it's real, on-disk data) — a lease
  /// only keeps a file from being deleted, not from being visible.
  ///
  /// This is what closes the gap the single-pass `exclude` parameter (an
  /// earlier version of this cache) left open: `exclude` only protected a
  /// path from the ONE eviction pass its own commit triggered. A different
  /// key's commit could still queue an EARLIER pass that runs, sees this
  /// path already written to disk, and deletes it while this operation is
  /// still waiting for its own cache transaction — so `ensureAudio`
  /// could resolve to a path a concurrent operation had already deleted.
  /// Pinning the path synchronously, in the same synchronous stretch of
  /// code right after the rename that created it (before any further
  /// `await`), closes that window: no eviction pass — whichever key
  /// triggered it, whenever it happens to run — can ever see this path as
  /// evictable until the caller that received it explicitly releases it.
  final Map<String, int> _pinnedPaths = {};
  final Map<int, String> _activeLeases = {};
  int _nextLeaseId = 0;

  TtsAudioLease _createLease(String path) {
    final id = ++_nextLeaseId;
    _activeLeases[id] = path;
    _pinnedPaths[path] = (_pinnedPaths[path] ?? 0) + 1;
    return TtsAudioLease._(path, () => _releaseLease(id));
  }

  Future<void> _releaseLease(int id) {
    // Drop ownership synchronously: UI lifecycle methods such as stop() and
    // dispose() cannot await cleanup, but must stop protecting the clip as
    // soon as they relinquish it. The filesystem trim itself remains in the
    // serialized transaction queue.
    final path = _activeLeases.remove(id);
    if (path == null) return Future.value();
    final count = _pinnedPaths[path];
    if (count == null || count <= 1) {
      _pinnedPaths.remove(path);
    } else {
      _pinnedPaths[path] = count - 1;
    }
    return _runCacheTransaction(_enforceCacheBudget);
  }

  Future<TtsAudioLease> _ensureAudioOnce(
    DialogueLine line, {
    required bool forceRegenerate,
  }) async {
    final path = await _cachePath(line);
    if (!forceRegenerate) {
      final cached = await _runCacheTransaction<TtsAudioLease?>(() async {
        final file = File(path);
        if (!await file.exists() || await file.length() < _minValidBytes) {
          return null;
        }
        await file.setLastModified(DateTime.now());
        return _createLease(path);
      });
      if (cached != null) return cached;
    }

    final bytes = await _synthesize(line);
    return _runCacheTransaction(() async {
      // Write through a temporary file and rename. Network synthesis stays
      // parallel across keys; only filesystem mutation is serialized.
      final temporary = File('$path.tmp');
      try {
        await temporary.writeAsBytes(bytes, flush: true);
        await temporary.rename(path);
      } catch (_) {
        if (await temporary.exists()) {
          try {
            await temporary.delete();
          } catch (_) {}
        }
        rethrow;
      }
      final lease = _createLease(path);
      await _enforceCacheBudget();
      return lease;
    });
  }

  /// Serializes the commit+evict tail across ALL cache keys — unlike
  /// `_pendingByKey` above, which only serializes operations that share
  /// the same key. Synthesis (the slow network part) for different keys
  /// still runs fully in parallel; only this fast, no-network step is
  /// funneled through a single chain, one at a time.
  ///
  /// Without this, two concurrent commits for DIFFERENT keys could each
  /// call `_enforceCacheBudget` against their own stale snapshot of the
  /// directory (taken via a separate, unsynchronized `dir.list()`), both
  /// compute "delete one file" independently, and both actually delete —
  /// removing more than necessary, sometimes leaving zero clips where one
  /// should have survived. Chaining every commit+evict step through this
  /// one queue guarantees each pass sees the fully up-to-date on-disk
  /// state left by the previous pass, so the SAME sort-and-trim loop in
  /// `_enforceCacheBudget` — which already only removes what's needed to
  /// reach the target — computes the correct answer every time instead of
  /// duplicating work against data another pass already acted on.
  Future<void> _cacheTransactionChain = Future.value();

  Future<T> _runCacheTransaction<T>(Future<T> Function() action) {
    final result = _cacheTransactionChain.then((_) => action());
    _cacheTransactionChain = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Deletes cached audio for these lines so the next ensureAudio() call
  /// re-synthesizes them from scratch. Callers are responsible for
  /// releasing its own leases first. A file still leased by another owner
  /// is deliberately preserved.
  Future<void> clearCache(List<DialogueLine> lines) async {
    final paths = await Future.wait(lines.map(_cachePath));
    await _runCacheTransaction(() async {
      for (final path in paths) {
        if (_pinnedPaths.containsKey(path)) continue;
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    });
  }

  /// Keeps the cache directory under [_cacheBudget] total bytes, evicting
  /// the least-recently-used clips first (see [ensureAudio]'s
  /// `setLastModified` touch on cache hits). Also sweeps orphaned
  /// `.tmp` files left behind by a write that never completed — a normal
  /// in-progress `.tmp` is only ever a few hundred milliseconds old, so
  /// anything older than a minute is a crash/kill remnant.
  ///
  /// Only ever called inside [_runCacheTransaction]'s single global queue —
  /// never call this directly from a code path that could run
  /// concurrently with another call, or the whole point of that queue
  /// (one consistent, up-to-date directory snapshot per pass) is lost.
  /// Any path currently in [_pinnedPaths] is still counted toward the
  /// budget total (it's real, on-disk data) but is never itself picked
  /// for eviction — see that field's doc for why that matters.
  Future<void> _enforceCacheBudget() async {
    try {
      final dir = await _dir;
      final clips = <File>[];
      final sizes = <File, int>{};
      final modified = <File, DateTime>{};
      var totalBytes = 0;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (entity.path.endsWith('.tmp')) {
          if (DateTime.now().difference(stat.modified) >
              const Duration(minutes: 1)) {
            try {
              await entity.delete();
            } catch (_) {}
          }
          continue;
        }
        totalBytes += stat.size;
        if (_pinnedPaths.containsKey(entity.path)) continue;
        clips.add(entity);
        sizes[entity] = stat.size;
        modified[entity] = stat.modified;
      }
      if (totalBytes <= _cacheBudget) return;
      clips.sort((a, b) => modified[a]!.compareTo(modified[b]!));
      final target = (_cacheBudget * _cacheTrimTargetRatio).round();
      for (final clip in clips) {
        if (totalBytes <= target) break;
        try {
          await clip.delete();
          totalBytes -= sizes[clip]!;
        } catch (_) {
          // Best-effort — a file another isolate/process already removed
          // must not block trimming the rest.
        }
      }
    } catch (_) {
      // Best-effort at the pass level too: a directory-listing failure
      // must never break TTS, and must never leave the transaction chain
      // permanently rejected (which would poison every later cache
      // transaction).
    }
  }

  // Telefonnotiz callers spell surnames letter by letter ("buchstabiert
  // S-T-Ä-D-T-L-E-R"). Sent as-is, edge-tts runs the hyphenated letters
  // together with no real gap; sending each letter as its own request
  // isn't reliable either (a bare single umlaut like "Ä" can come back
  // with no audio at all). Turning each hyphen into a period instead
  // keeps it one request but makes edge-tts treat every letter as its
  // own sentence, which comes out clearly paused.
  static final _spelledOutPattern = RegExp(
    r'\b(?:[A-Za-zÄÖÜäöüß]-){2,}[A-Za-zÄÖÜäöüß]\b',
  );

  String _forSynthesis(String text) {
    return text.replaceAllMapped(_spelledOutPattern, (m) {
      final letters = m.group(0)!.split('-');
      return '${letters.join('. ')}.';
    });
  }

  Future<Uint8List> _synthesize(DialogueLine line) async {
    final token =
        await (debugIdTokenOverride?.call() ??
            AuthService.instance.requireIdToken());
    final voiceGender = _effectiveVoiceGender(line).requestValue;
    final body = <String, String>{
      'speaker': line.speaker,
      'text': _forSynthesis(line.text),
    };
    if (voiceGender != null) body['voice_gender'] = voiceGender;
    final res = await _httpClient
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/tts'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('TTS ${res.statusCode}: ${res.body}');
    }
    if (res.bodyBytes.length < _minValidBytes) {
      throw Exception(
        'TTS returned a suspiciously short clip '
        '(${res.bodyBytes.length} bytes) for "${line.text}"',
      );
    }
    return res.bodyBytes;
  }
}
