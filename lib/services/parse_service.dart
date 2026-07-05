import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ParseService {
  ParseService._();
  static final instance = ParseService._();
  static const _timeout = Duration(seconds: 60);

  Future<String> convertPdf(Uint8List pdfBytes) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/convert'),
      headers: {
        'X-App-Secret': ApiConfig.secret,
        'Content-Type': 'application/octet-stream',
      },
      body: pdfBytes,
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Ошибка конвертации ${res.statusCode}: ${res.body}');
    }
    return (jsonDecode(res.body)['markdown'] as String);
  }

  Future<List<dynamic>> parseSection(String markdown, String sectionType) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/parse'),
      headers: {
        'X-App-Secret': ApiConfig.secret,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'markdown': markdown, 'section_type': sectionType}),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Ошибка парсинга ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  /// Parses a whole section by splitting it into per-variant chunks and
  /// sending them to Gemini in small batches. Large sections (Hören with
  /// long dialogues) time out when sent whole — small batches are fast and
  /// a single failed batch doesn't kill the entire section.
  Future<List<dynamic>> parseSectionInBatches(
    String sectionMarkdown,
    String anchor,
    String sectionType, {
    int maxCharsPerBatch = 7000,
    void Function(int done, int total)? onProgress,
  }) async {
    final variants = splitVariants(sectionMarkdown, anchor);
    final batches = _batch(variants, maxCharsPerBatch);

    // Up to 3 batches in flight: Gemini generation dominates the wall time,
    // so parallel requests cut it ~3x. 429s from stricter rate limits are
    // absorbed by _parseWithRetry's backoff.
    const concurrency = 3;
    final results = <dynamic>[];
    final errors = <String>[];
    var done = 0;
    onProgress?.call(0, batches.length);
    for (var i = 0; i < batches.length; i += concurrency) {
      final slice = batches.sublist(
          i, (i + concurrency).clamp(0, batches.length));
      final settled = await Future.wait(slice.map((b) async {
        try {
          return await _parseWithRetry(b, sectionType);
        } catch (e) {
          errors.add(e.toString());
          return const <dynamic>[];
        }
      }));
      for (final r in settled) {
        results.addAll(r);
      }
      done += slice.length;
      onProgress?.call(done, batches.length);
    }

    // Everything failed → surface the error; partial success → keep results.
    if (results.isEmpty && errors.isNotEmpty) {
      throw Exception(errors.first);
    }
    return _mergeByVariant(results);
  }

  /// The PDF often repeats a variant header (transcript block + questions
  /// block, or old/new question versions), so different batches can return
  /// entries with the same variant_number. Merge them into one.
  List<dynamic> _mergeByVariant(List<dynamic> raw) {
    final byNum = <int, Map<String, dynamic>>{};
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final n = (item['variant_number'] as num?)?.toInt() ?? 0;
      final existing = byNum[n];
      if (existing == null) {
        byNum[n] = Map.of(item);
        continue;
      }
      for (final key in item.keys) {
        final v = item[key];
        if (v == null) continue;
        final ev = existing[key];
        if (ev == null || (ev is String && ev.isEmpty)) {
          existing[key] = v;
        } else if (ev is List && v is List) {
          existing[key] = switch (key) {
            'questions' => _dedupedConcat(ev, v, 'number'),
            'option_pool' => _dedupedConcat(ev, v, 'letter'),
            'texts' => _dedupedConcat(ev, v, 'title'),
            _ => [...ev, ...v],
          };
        }
      }
    }
    final nums = byNum.keys.toList()..sort();
    return nums.map((n) => byNum[n]!).toList();
  }

  List<dynamic> _dedupedConcat(List a, List b, String keyField) {
    final seen = a.whereType<Map>().map((e) => e[keyField]).toSet();
    return [
      ...a,
      ...b.whereType<Map>().where((e) => !seen.contains(e[keyField])),
    ];
  }

  Future<List<dynamic>> _parseWithRetry(String markdown, String sectionType) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await parseSection(markdown, sectionType);
      } catch (e) {
        lastError = e;
        // 429 = Gemini rate limit — needs a much longer pause than a flaky 500
        final seconds = e.toString().contains('429') ? 15 : 2 + attempt * 3;
        await Future.delayed(Duration(seconds: seconds));
      }
    }
    throw Exception(lastError.toString());
  }

  /// Splits a section's markdown into one chunk per variant, using the
  /// "`anchor` … вариант" header lines as boundaries.
  List<String> splitVariants(String sectionMarkdown, String anchor) {
    final lines = sectionMarkdown.split('\n');
    final starts = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (_isHeader(lines[i], anchor)) {
        starts.add(i);
      }
    }
    if (starts.isEmpty) return [sectionMarkdown];

    final chunks = <String>[];
    for (var j = 0; j < starts.length; j++) {
      final end = j + 1 < starts.length ? starts[j + 1] : lines.length;
      chunks.add(lines.sublist(starts[j], end).join('\n'));
    }
    return chunks;
  }

  /// Groups variant chunks into batches no longer than [maxChars] each
  /// (a single oversized variant still becomes its own batch).
  List<String> _batch(List<String> chunks, int maxChars) {
    final batches = <String>[];
    final current = StringBuffer();
    for (final c in chunks) {
      if (current.isNotEmpty && current.length + c.length > maxChars) {
        batches.add(current.toString());
        current.clear();
      }
      if (current.isNotEmpty) current.write('\n\n');
      current.write(c);
    }
    if (current.isNotEmpty) batches.add(current.toString());
    return batches;
  }

  // Every variant header in the source PDF: "<anchor> (вариант №N)".
  // "Text 1"/"Text 2" are Lesen Teil 2's own header form; "Beschwerde"
  // covers "Lesen und Schreiben (Teil) Beschwerde".
  static const knownAnchors = [
    'Hören Teil 1', 'Hören Teil 2', 'Hören Teil 3', 'Hören Teil 4',
    'Telefonnotiz', 'Sprachbausteine Teil 1', 'Sprachbausteine Teil 2',
    'Lesen Teil 1', 'Text 1', 'Text 2', 'Lesen Teil 3', 'Lesen Teil 4',
    'Beschwerde',
  ];

  // Lines like "(звуковая дорожка от … – Hören Teil 1 вариант №1)" mention
  // an anchor + "вариант" but are audio references, not section headers.
  bool _isHeader(String line, String anchor) =>
      line.contains(anchor) &&
      line.toLowerCase().contains('вариант') &&
      !line.contains('дорожка');

  // Non-exercise blocks (forum-writing links, oral exam materials) have no
  // variant headers, so without these markers they'd get glued to the
  // preceding section.
  bool _isStopMarker(String line) {
    final t = line.trim();
    return t == 'Forumsbeitrag' ||
        t == 'Forumsbeitrag 2' ||
        t.startsWith('Mündliche Prüfung');
  }

  String extractSection(String fullMarkdown, String anchor) {
    final lines = fullMarkdown.split('\n');

    // Start at the first real variant header (a bare mention in the intro
    // or table of contents must not match); fall back to any mention.
    var start = lines.indexWhere((l) => _isHeader(l, anchor));
    if (start == -1) start = lines.indexWhere((l) => l.contains(anchor));
    if (start == -1) return '';

    final otherAnchors = knownAnchors.where((a) => a != anchor).toList();
    int end = lines.length;
    for (int i = start + 5; i < lines.length; i++) {
      final line = lines[i];
      if (otherAnchors.any((a) => _isHeader(line, a)) || _isStopMarker(line)) {
        end = i;
        break;
      }
    }

    return lines.sublist(start, end).join('\n');
  }
}
