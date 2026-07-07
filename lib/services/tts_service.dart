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

  /// Splits "Speaker: text" formatted dialogue into lines. Text with no
  /// such prefixes (a plain monologue) becomes one or more sentence-sized
  /// lines, kept under [_maxCharsPerRequest] each.
  ///
  /// The source PDF hard-wraps and hyphenates lines mid-sentence (e.g.
  /// "... neu ge-" / "stalten und ..."), and Gemini's extraction sometimes
  /// preserves those raw line breaks. A continuation raw line — one with
  /// no "Speaker:" prefix — is folded into the previous line instead of
  /// being dropped, which used to silently cut the sentence (and its
  /// audio) short right at the wrap point.
  List<DialogueLine> parseLines(String text) {
    final lines = <DialogueLine>[];
    final pattern = RegExp(r'^(.+?):\s+(.+)$');
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = pattern.firstMatch(line);
      if (m != null) {
        lines.add(DialogueLine(m.group(1)!.trim(), m.group(2)!.trim()));
      } else if (lines.isNotEmpty) {
        final last = lines.removeLast();
        // Hyphenated word split across the wrap ("ge-" + "stalten") joins
        // with no space; a plain sentence wrap joins with one.
        final joined = last.text.endsWith('-')
            ? last.text.substring(0, last.text.length - 1) + line
            : '${last.text} $line';
        lines.add(DialogueLine(last.speaker, joined));
      } else {
        lines.add(DialogueLine('', line));
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
