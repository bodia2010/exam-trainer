import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// One line of a dialogue/monologue: who says it and what.
class DialogueLine {
  final String speaker;
  final String text;
  const DialogueLine(this.speaker, this.text);
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

  Future<Directory> get _dir async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/tts_cache');
    if (!d.existsSync()) d.createSync(recursive: true);
    return _cacheDir = d;
  }

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
  /// gebucht"") for a new speaker. The name itself is 1-2 capitalized
  /// words (plain names, or "Herr"/"Frau" + surname), immediately
  /// followed by ": ".
  static final _turnStartPattern = RegExp(
      r'(?:^|(?<=[.!?…])\s+)([A-ZÄÖÜ][\wäöüß]*(?:\s[A-ZÄÖÜ][\wäöüß]*)?):\s+');

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
  List<DialogueLine> parseLines(String text) {
    final normalized = text
        .replaceAll(RegExp(r'-\n\s*'), '')
        .replaceAll('\n', ' ')
        .trim();
    if (normalized.isEmpty) return const [];

    final matches = _turnStartPattern.allMatches(normalized).toList();
    final lines = <DialogueLine>[];
    if (matches.isEmpty) {
      lines.add(DialogueLine('', normalized));
    } else {
      for (var i = 0; i < matches.length; i++) {
        final m = matches[i];
        final end = i + 1 < matches.length ? matches[i + 1].start : normalized.length;
        final turnText = normalized.substring(m.end, end).trim();
        if (turnText.isEmpty) continue;
        lines.add(DialogueLine(m.group(1)!.trim(), turnText));
      }
      // Text before the first recognized turn (or a document with no
      // recognizable speaker pattern at all) — keep it rather than
      // silently drop it.
      if (matches.first.start > 0) {
        final lead = normalized.substring(0, matches.first.start).trim();
        if (lead.isNotEmpty) lines.insert(0, DialogueLine('', lead));
      }
    }

    // A monologue (Telefonnotiz, Hören Teil 2-4 announcements) has no
    // "Speaker:" turns, so every line above landed with an empty speaker —
    // and an empty speaker always picked a default MALE voice server-side,
    // even when the caller plainly introduces themselves as "Frau X".
    // Scan the narrator's own self-introduction and use it as a shared
    // speaker tag for every chunk of this monologue, so gender detection
    // (see backend tts.py's _gender()) actually has something to go on.
    if (lines.isNotEmpty && lines.every((l) => l.speaker.isEmpty)) {
      final narrator = _detectNarrator(text);
      if (narrator != null) {
        for (var i = 0; i < lines.length; i++) {
          lines[i] = DialogueLine(narrator, lines[i].text);
        }
      }
    }

    return lines.expand(_splitIfTooLong).toList();
  }

  static final _narratorPattern =
      RegExp(r'\b(Herr|Frau)\s+([A-ZÄÖÜ][a-zäöüß]+)');

  /// Finds a self-introduction like "... hier spricht Frau Meier ..." or
  /// "Herr Schmitt am Apparat" so the TTS voice matches the caller's
  /// gender instead of falling back to a fixed default.
  String? _detectNarrator(String text) {
    final m = _narratorPattern.firstMatch(text);
    return m == null ? null : '${m.group(1)} ${m.group(2)}';
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
      final candidate =
          buffer.isEmpty ? sentence : '${buffer.toString()} $sentence';
      if (candidate.length > _maxCharsPerRequest && buffer.isNotEmpty) {
        yield DialogueLine(line.speaker, buffer.toString());
        buffer.clear();
      }
      // A single "sentence" that alone exceeds the limit (no punctuation
      // to split on) still has to be sent somehow — hard-split by words.
      if (sentence.length > _maxCharsPerRequest) {
        for (final chunk in _hardSplit(sentence, _maxCharsPerRequest)) {
          yield DialogueLine(line.speaker, chunk);
        }
        continue;
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(sentence);
    }
    if (buffer.isNotEmpty) {
      yield DialogueLine(line.speaker, buffer.toString());
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

  Future<String> _cachePath(DialogueLine line) async {
    final key =
        sha1.convert(utf8.encode('${line.speaker}|${line.text}')).toString();
    final dir = await _dir;
    return '${dir.path}/$key.mp3';
  }

  // A genuine spoken line is always well over this many bytes; anything
  // smaller means a previous request got cut off (network hiccup, function
  // timeout) and was cached as a "valid" but silent/truncated clip.
  static const _minValidBytes = 512;

  /// Returns a local file path with this line's audio, synthesizing and
  /// caching it first if necessary. Pass [forceRegenerate] to ignore and
  /// overwrite whatever is already cached.
  Future<String> ensureAudio(DialogueLine line,
      {bool forceRegenerate = false}) async {
    final path = await _cachePath(line);
    final file = File(path);
    if (!forceRegenerate &&
        await file.exists() &&
        await file.length() >= _minValidBytes) {
      return path;
    }

    final bytes = await _synthesize(line);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  /// Deletes cached audio for these lines so the next ensureAudio() call
  /// re-synthesizes them from scratch.
  Future<void> clearCache(List<DialogueLine> lines) async {
    for (final line in lines) {
      final path = await _cachePath(line);
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  // Telefonnotiz callers spell surnames letter by letter ("buchstabiert
  // S-T-Ä-D-T-L-E-R"). Sent as-is, edge-tts runs the hyphenated letters
  // together with no real gap; sending each letter as its own request
  // isn't reliable either (a bare single umlaut like "Ä" can come back
  // with no audio at all). Turning each hyphen into a period instead
  // keeps it one request but makes edge-tts treat every letter as its
  // own sentence, which comes out clearly paused.
  static final _spelledOutPattern =
      RegExp(r'\b(?:[A-Za-zÄÖÜäöüß]-){2,}[A-Za-zÄÖÜäöüß]\b');

  String _forSynthesis(String text) {
    return text.replaceAllMapped(_spelledOutPattern, (m) {
      final letters = m.group(0)!.split('-');
      return '${letters.join('. ')}.';
    });
  }

  Future<Uint8List> _synthesize(DialogueLine line) async {
    final token = await AuthService.instance.requireIdToken();
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/tts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
          {'speaker': line.speaker, 'text': _forSynthesis(line.text)}),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('TTS ${res.statusCode}: ${res.body}');
    }
    if (res.bodyBytes.length < _minValidBytes) {
      throw Exception('TTS returned a suspiciously short clip '
          '(${res.bodyBytes.length} bytes) for "${line.text}"');
    }
    return res.bodyBytes;
  }
}
