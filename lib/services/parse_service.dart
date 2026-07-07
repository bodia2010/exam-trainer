import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// One exercise variant found by the AI structure-discovery pass — a
/// section type + where it starts in the document. No literal text
/// matching involved, so it works regardless of the PDF's language or
/// labeling convention (see ParseService.discoverSections).
class DiscoveredItem {
  final String sectionType;
  final num variantNumber;
  final String? versionLabel;
  final int startLine;

  const DiscoveredItem({
    required this.sectionType,
    required this.variantNumber,
    required this.versionLabel,
    required this.startLine,
  });
}

class ParseService {
  ParseService._();
  static final instance = ParseService._();
  static const _timeout = Duration(seconds: 60);
  // Discovery sends the whole document (~150K tokens) in one call — needs
  // more room than a typical small per-variant parse call.
  static const _discoveryTimeout = Duration(seconds: 120);

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

  Future<List<dynamic>> parseSection(String markdown, String sectionType,
      {Duration? timeout}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/parse'),
      headers: {
        'X-App-Secret': ApiConfig.secret,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'markdown': markdown, 'section_type': sectionType}),
    ).timeout(timeout ?? _timeout);
    if (res.statusCode != 200) {
      throw Exception('Ошибка парсинга ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  /// Finds every exercise variant in the whole document in one pass, by
  /// having Gemini recognize each exercise's STRUCTURE (not a hardcoded
  /// literal label) — works for any language/labeling convention, unlike
  /// the old regex-anchor approach. Each source line is numbered so Gemini
  /// reports an exact line index instead of quoting text verbatim (which
  /// is unreliable over a ~150K-token document).
  Future<List<DiscoveredItem>> discoverSections(String markdown) async {
    final lines = markdown.split('\n');
    final numbered = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      numbered.writeln('${i.toString().padLeft(5, '0')}: ${lines[i]}');
    }
    final raw = await parseSection(numbered.toString(), 'discover',
        timeout: _discoveryTimeout);
    final items = raw
        .whereType<Map<String, dynamic>>()
        .map((it) => DiscoveredItem(
              sectionType: (it['section_type'] as String?) ?? '',
              variantNumber: (it['variant_number'] as num?) ?? 0,
              versionLabel: it['version_label'] as String?,
              startLine: (it['start_line'] as num?)?.toInt() ?? 0,
            ))
        .where((it) => it.sectionType.isNotEmpty)
        .toList()
      ..sort((a, b) => a.startLine.compareTo(b.startLine));
    return items;
  }

  /// Slices the document into one raw text chunk per discovered item,
  /// grouped by section type. An item's end boundary is the next item's
  /// start — in *document* order across every type, not just its own —
  /// so nothing from a neighboring section leaks in.
  Map<String, List<String>> chunksBySectionType(
      String markdown, List<DiscoveredItem> items) {
    final lines = markdown.split('\n');
    final result = <String, List<String>>{};
    for (var i = 0; i < items.length; i++) {
      final start = items[i].startLine.clamp(0, lines.length);
      final end = i + 1 < items.length
          ? items[i + 1].startLine.clamp(0, lines.length)
          : lines.length;
      if (end <= start) continue;
      final chunk = lines.sublist(start, end).join('\n');
      result.putIfAbsent(items[i].sectionType, () => []).add(chunk);
    }
    return result;
  }

  /// Parses one section's variant chunks by batching them and sending to
  /// Gemini in parallel. Small batches (rather than the whole section at
  /// once) keep each request fast and mean one failed batch doesn't lose
  /// the rest of the section.
  Future<List<dynamic>> parseChunksInBatches(
    List<String> chunks,
    String sectionType, {
    int maxCharsPerBatch = 7000,
    void Function(int done, int total)? onProgress,
  }) async {
    final batches = _batch(chunks, maxCharsPerBatch);

    // Batches in flight: Gemini generation dominates the wall time, so
    // parallel requests cut it proportionally. Sized for a paid-tier key
    // (1000 RPM); free-tier 429s are absorbed by _parseWithRetry's backoff.
    const concurrency = 6;
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

  /// The PDF often repeats a variant header (e.g. transcript block +
  /// questions block of the same variant), so different batches can return
  /// entries with the same variant_number — those are merged. Reworked
  /// editions carry a distinct `version` label and stay separate variants.
  List<dynamic> _mergeByVariant(List<dynamic> raw) {
    final byNum = <String, Map<String, dynamic>>{};
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final n = (item['variant_number'] as num?)?.toInt() ?? 0;
      final version = (item['version'] as String?)?.trim() ?? '';
      final key = '$n|${version.toLowerCase()}';
      final existing = byNum[key];
      if (existing == null) {
        byNum[key] = Map.of(item);
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
    final result = byNum.values.toList()
      ..sort((a, b) {
        final na = (a['variant_number'] as num?)?.toInt() ?? 0;
        final nb = (b['variant_number'] as num?)?.toInt() ?? 0;
        if (na != nb) return na.compareTo(nb);
        // original (no version) first, then editions alphabetically
        final va = (a['version'] as String?) ?? '';
        final vb = (b['version'] as String?) ?? '';
        return va.compareTo(vb);
      });
    return result;
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
}
