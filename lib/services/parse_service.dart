import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

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

/// All the raw text chunks discovery found for one (sectionType,
/// variantNumber) pair — e.g. the original + every reworked edition of
/// "Hören Teil 1 вариант №5". Kept together (not cached/parsed per
/// individual chunk) because a reworked edition is often NOT
/// self-contained — e.g. a "Новый вариант вопроса" block only restates
/// one changed question and relies on the original's dialogue text right
/// above it. Splitting them into isolated calls would starve the model of
/// context it needs to produce a complete object.
class VariantGroup {
  final num variantNumber;
  final List<String> chunks;

  const VariantGroup({required this.variantNumber, required this.chunks});

  String get joinedText => chunks.join('\n\n${ParseService.itemDelimiter}\n\n');
}

class ParseService {
  ParseService._();
  static final instance = ParseService._();
  static const _timeout = Duration(seconds: 60);
  // Discovery sends the whole document (~150K tokens) in one call — needs
  // more room than a typical small per-variant parse call.
  static const _discoveryTimeout = Duration(seconds: 120);

  /// Bump this whenever a prompt or parsing rule changes in a way that
  /// alters output for existing content — it's mixed into every cache key
  /// so old (now-stale) cached results become unreachable instead of being
  /// served forever under the same input text.
  static const _cacheVersion = 'v3';

  /// Marker inserted between chunks of the same variant group. Discovery
  /// already decided these are separate editions — the marker tells the
  /// parse prompt not to re-judge that itself, which (without it) was
  /// silently collapsing several distinct editions into one output object
  /// and discarding the rest.
  static const itemDelimiter = '<<<ITEM>>>';

  /// Every request authenticates as the signed-in Firebase user instead of
  /// the old single shared APP_SECRET — a leaked token only ever identifies
  /// (and can be individually rate-limited/banned as) one account, not
  /// every install of the app.
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.requireIdToken();
    return {'Authorization': 'Bearer $token'};
  }

  Future<String> convertPdf(Uint8List pdfBytes) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/convert'),
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/octet-stream',
      },
      body: pdfBytes,
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Ошибка конвертации ${res.statusCode}: ${res.body}');
    }
    return (jsonDecode(res.body)['markdown'] as String);
  }

  String _hash(String text) =>
      sha256.convert(utf8.encode('$_cacheVersion|$text')).toString();

  Future<dynamic> _cacheGet(String key) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/cache?hash=$key'),
        headers: await _authHeaders(),
      ).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['hit'] == true ? body['value'] : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheSet(String key, dynamic value) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/cache'),
        headers: {
          ...await _authHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'hash': key, 'value': value}),
      ).timeout(_timeout);
    } catch (_) {
      // best-effort — a failed cache write must never break the import
    }
  }

  /// Fast path for an exact re-import of a document already seen before
  /// (byte-identical extracted markdown): skips discovery + parsing
  /// entirely. Misses whenever anything in the document changed, however
  /// small — see [parseVariantGroups] for the granular cache that still
  /// helps in that case.
  Future<Map<String, List<dynamic>>?> getCachedSections(
      String markdown) async {
    final cached = await _cacheGet(_hash('doc|$markdown'));
    if (cached == null) return null;
    return (cached as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as List<dynamic>));
  }

  Future<void> cacheSections(
      String markdown, Map<String, List<dynamic>> sections) async {
    await _cacheSet(_hash('doc|$markdown'), sections);
  }

  Future<List<dynamic>> parseSection(String markdown, String sectionType,
      {Duration? timeout}) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/parse'),
      headers: {
        ...await _authHeaders(),
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

  /// Slices the document into one raw text chunk per discovered item, then
  /// groups those chunks by (section type, variant number) into
  /// [VariantGroup]s — the unit both parsing and caching operate on. An
  /// item's end boundary is the next item's start in *document* order
  /// across every type, not just its own, so nothing from a neighboring
  /// section leaks in.
  Map<String, List<VariantGroup>> groupChunksBySectionType(
      String markdown, List<DiscoveredItem> items) {
    final lines = markdown.split('\n');
    final bySectionType = <String, Map<num, List<String>>>{};
    for (var i = 0; i < items.length; i++) {
      final start = items[i].startLine.clamp(0, lines.length);
      final end = i + 1 < items.length
          ? items[i + 1].startLine.clamp(0, lines.length)
          : lines.length;
      if (end <= start) continue;
      final chunk = lines.sublist(start, end).join('\n');
      bySectionType
          .putIfAbsent(items[i].sectionType, () => {})
          .putIfAbsent(items[i].variantNumber, () => [])
          .add(chunk);
    }
    return bySectionType.map((type, byVariant) => MapEntry(
        type,
        byVariant.entries
            .map((e) =>
                VariantGroup(variantNumber: e.key, chunks: e.value))
            .toList()));
  }

  /// Parses one section's variant groups, sending each group as its own
  /// Gemini call (in parallel, bounded concurrency). Caching happens per
  /// group, keyed by that group's own text — so editing/adding content
  /// anywhere else in the document doesn't invalidate variants that didn't
  /// change, unlike a whole-document cache key.
  Future<List<dynamic>> parseVariantGroups(
    List<VariantGroup> groups,
    String sectionType, {
    void Function(int done, int total)? onProgress,
  }) async {
    // Groups in flight: Gemini generation dominates the wall time, so
    // parallel requests cut it proportionally. Sized for a paid-tier key
    // (1000 RPM); free-tier 429s are absorbed by _parseWithRetry's backoff.
    const concurrency = 6;
    final results = <dynamic>[];
    final errors = <String>[];
    var done = 0;
    onProgress?.call(0, groups.length);
    for (var i = 0; i < groups.length; i += concurrency) {
      final slice =
          groups.sublist(i, (i + concurrency).clamp(0, groups.length));
      final settled = await Future.wait(slice.map((g) async {
        final text = g.joinedText;
        final key = _hash('group|$sectionType|$text');
        try {
          final cached = await _cacheGet(key);
          if (cached != null) return cached as List<dynamic>;
          final parsed = await _parseWithRetry(text, sectionType);
          final expanded = _expandSentinels(parsed, sectionType);
          // Cache the EXPANDED result — every consumer (including future
          // cache hits) gets ready-to-use, fully self-contained objects,
          // so nothing downstream needs to know sentinels ever existed.
          unawaited(_cacheSet(key, expanded));
          return expanded;
        } catch (e) {
          errors.add(e.toString());
          return const <dynamic>[];
        }
      }));
      for (final r in settled) {
        results.addAll(r);
      }
      done += slice.length;
      onProgress?.call(done, groups.length);
    }

    // Everything failed → surface the error; partial success → keep results.
    if (results.isEmpty && errors.isNotEmpty) {
      throw Exception(errors.first);
    }
    return _mergeByVariant(results);
  }

  /// Sent by the prompt for a reworked edition's field that is word-for-
  /// word identical to the original variant's — saves Gemini from
  /// retyping large shared content (a reading passage, a dialogue
  /// transcript) in every edition. Expanded back to the real value here,
  /// right after parsing, so every consumer downstream (cache, storage,
  /// exercise screens) only ever sees complete, self-contained objects.
  static const _sameSentinel = '<<SAME_AS_ORIGINAL>>';

  List<dynamic> _expandSentinels(List<dynamic> group, String sectionType) {
    final objects = group.whereType<Map<String, dynamic>>().toList();
    final base = objects.firstWhere(
      (o) => o['version'] == null,
      orElse: () => objects.isNotEmpty ? objects.first : <String, dynamic>{},
    );
    if (base.isEmpty) return group;
    for (final obj in objects) {
      if (identical(obj, base)) continue;
      for (final field in ['texts', 'option_pool', 'letter_text', 'all_options']) {
        if (obj[field] == _sameSentinel && base.containsKey(field)) {
          obj[field] = base[field];
        }
      }
      // hoeren_teil1: a whole question_pairs ENTRY can be the sentinel
      // (not just a nested field) — the prompt uses this for pairs a
      // block doesn't restate at all, index-aligned with the original.
      final pairs = obj['question_pairs'];
      final basePairs = base['question_pairs'];
      if (pairs is List && basePairs is List) {
        for (var i = 0; i < pairs.length && i < basePairs.length; i++) {
          if (pairs[i] == _sameSentinel) {
            pairs[i] = basePairs[i];
          }
        }
      }
    }
    // Safety net: a sentinel that's still present after expansion means
    // the base object was missing, malformed, or didn't have that field
    // — surface it loudly instead of letting the literal placeholder
    // string silently reach storage/UI.
    for (final obj in objects) {
      final leaks = _findSentinelPaths(obj, '');
      if (leaks.isNotEmpty) {
        debugPrint('[dedup] UNRESOLVED <<SAME_AS_ORIGINAL>> in $sectionType '
            'variant=${obj['variant_number']} version=${obj['version']}: '
            '${leaks.join(', ')}');
      }
    }
    return group;
  }

  List<String> _findSentinelPaths(dynamic value, String path) {
    final hits = <String>[];
    if (value == _sameSentinel) {
      hits.add(path.isEmpty ? '<root>' : path);
    } else if (value is Map) {
      for (final entry in value.entries) {
        hits.addAll(_findSentinelPaths(entry.value, '$path.${entry.key}'));
      }
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        hits.addAll(_findSentinelPaths(value[i], '$path[$i]'));
      }
    }
    return hits;
  }

  /// A variant group can still return more than one object (e.g.
  /// telefonnotiz nests every edition of a variant under one object's
  /// "versions" list, so several groups sharing a variant_number must be
  /// combined into one final entry). Reworked editions with the universal
  /// schema carry a distinct `version` label and stay separate variants.
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
}
