import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_config.dart';

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
  static const _timeout = Duration(seconds: 30);

  Directory? _cacheDir;

  Future<Directory> get _dir async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/tts_cache');
    if (!d.existsSync()) d.createSync(recursive: true);
    return _cacheDir = d;
  }

  /// Splits "Speaker: text" formatted dialogue into lines. Text with no
  /// such prefixes (a plain monologue) becomes a single line.
  List<DialogueLine> parseLines(String text) {
    final lines = <DialogueLine>[];
    final pattern = RegExp(r'^(.+?):\s+(.+)$');
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = pattern.firstMatch(line);
      if (m != null) {
        lines.add(DialogueLine(m.group(1)!.trim(), m.group(2)!.trim()));
      }
    }
    if (lines.isEmpty && text.trim().isNotEmpty) {
      lines.add(DialogueLine('', text.trim()));
    }
    return lines;
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

  Future<Uint8List> _synthesize(DialogueLine line) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/tts'),
      headers: {
        'X-App-Secret': ApiConfig.secret,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'speaker': line.speaker, 'text': line.text}),
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
