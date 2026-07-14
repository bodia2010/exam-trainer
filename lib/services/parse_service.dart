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
  // MarkItDown's PDF->Markdown conversion does real layout/table analysis
  // server-side with no artificial cap of its own — a long or
  // image/table-heavy document can comfortably clear 60s. 60s was too
  // tight and surfaced as a raw TimeoutException on otherwise-valid PDFs.
  static const _convertTimeout = Duration(seconds: 180);

  /// Bump whichever of these applies whenever a prompt or parsing rule
  /// changes in a way that alters output for existing content — each is a
  /// literal (unhashed) segment of its cache key so old (now-stale) cached
  /// results become unreachable instead of being served forever under the
  /// same input text.
  ///
  /// Kept as two independent counters, not one, because discovery is by
  /// far the most expensive call in the whole import — it sends the
  /// entire document (~150K+ tokens) to a pricier model, while every
  /// parse call after it is a small chunk on a cheap model (see
  /// [discoverSections]'s doc comment). A single shared version bumped
  /// for a parse-only prompt tweak (e.g. one section type's field list)
  /// used to also evict every cached discovery result, forcing a full
  /// re-discovery of documents whose discovery output hadn't changed at
  /// all — confirmed as the dominant driver of API spend during a
  /// session of rapid parse-prompt iteration on the same test document.
  static const _discoverCacheVersion = 'v30';
  static const _parseCacheVersion = 'v35';

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

  /// Free-tier imports skip the whole-document cache entirely (see
  /// [getCachedSections]/[cacheSections] callers in ImportScreen) — it's
  /// unsafe to share between tiers, since it stores the FULL assembled
  /// result under a key that doesn't encode which tier produced it.
  Future<bool> isPremium() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/me'), headers: await _authHeaders())
          .timeout(_timeout);
      if (res.statusCode != 200) return false;
      return (jsonDecode(res.body) as Map<String, dynamic>)['isPremium'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<String> convertPdf(Uint8List pdfBytes) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/convert'),
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/octet-stream',
      },
      body: pdfBytes,
    ).timeout(_convertTimeout);
    if (res.statusCode != 200) {
      throw Exception('Ошибка конвертации ${res.statusCode}: ${res.body}');
    }
    return (jsonDecode(res.body)['markdown'] as String);
  }

  String _hash(String text) => sha256.convert(utf8.encode(text)).toString();

  /// Builds the literal key sent to `/api/cache`: `<version>|<type>|<hash>`.
  /// Version and type are kept as plain (unhashed) segments — the backend
  /// can then log cache hit/miss broken down by [type] (`doc`/`group`/
  /// `discover`) just by splitting the key on `|`, without decoding the
  /// hash, and a version bump is a visibly different key rather than a
  /// change hidden inside the digest. [hashInput] is hashed exactly as the
  /// old pre-version-segment key was built (still `type|...`-shaped), so
  /// behavior/collision-safety is unchanged apart from the version no
  /// longer being folded into the digest.
  ///
  /// [version] is [_discoverCacheVersion] for a `discover` key,
  /// [_parseCacheVersion] for a `group` (per-chunk parse) key, and both
  /// joined for a `doc` key (the assembled whole-course result), since
  /// that one's content depends on both stages and must miss if either
  /// changed.
  String _cacheKey(String type, String hashInput, String version) =>
      '$version|$type|${_hash(hashInput)}';

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
    final cached = await _cacheGet(_cacheKey(
        'doc', 'doc|$markdown', '$_discoverCacheVersion.$_parseCacheVersion'));
    if (cached == null) return null;
    return (cached as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as List<dynamic>));
  }

  Future<void> cacheSections(
      String markdown, Map<String, List<dynamic>> sections) async {
    await _cacheSet(
        _cacheKey('doc', 'doc|$markdown',
            '$_discoverCacheVersion.$_parseCacheVersion'),
        sections);
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
    // Discovery output is pure structure (section type, variant number,
    // line position) — never the exam content itself — so unlike the
    // whole-document result cache, it's safe to share across BOTH tiers.
    // It's also the single most expensive call in the whole import (the
    // full document, ~150K tokens, identical cost regardless of premium
    // status), so a cache hit here is worth far more than any individual
    // parse-call cache hit.
    final docLines = markdown.split('\n');
    final key =
        _cacheKey('discover', 'discover|$markdown', _discoverCacheVersion);
    final cachedRaw = await _cacheGet(key);

    List<dynamic> raw;
    if (cachedRaw != null) {
      raw = cachedRaw as List<dynamic>;
    } else {
      final numbered = StringBuffer();
      for (var i = 0; i < docLines.length; i++) {
        numbered.writeln('${i.toString().padLeft(5, '0')}: ${docLines[i]}');
      }
      raw = await _parseWithRetry(numbered.toString(), 'discover',
          timeout: _discoveryTimeout);
      unawaited(_cacheSet(key, raw));
    }

    final items = _correctedItems(raw, docLines)
        .where((it) => it.sectionType.isNotEmpty)
        .toList()
      ..sort((a, b) => a.startLine.compareTo(b.startLine));
    return items;
  }

  /// Builds [DiscoveredItem]s with anchor-corrected start_lines, then a
  /// second de-duplication pass: the anchor itself is occasionally the
  /// wrong field instead of start_line — observed on the real fixture, an
  /// entry with the CORRECT start_line but a hallucinated anchor text
  /// naming the WRONG (adjacent) variant got "corrected" onto that
  /// neighbor's already-correct position, producing two entries claiming
  /// the same line. Whichever entry needed the SMALLER correction is
  /// almost certainly the one that was actually right; the other reverts
  /// to its own original start_line — a duplicate boundary is worse
  /// (silently drops one whole variant's chunk) than one entry keeping an
  /// uncorrected-but-plausible number, which is exactly the pre-anchor
  /// baseline behavior.
  @visibleForTesting
  List<DiscoveredItem> correctedItemsForTest(
          List<dynamic> raw, List<String> docLines) =>
      _correctedItems(raw, docLines);

  List<DiscoveredItem> _correctedItems(
      List<dynamic> raw, List<String> docLines) {
    final parsed = raw.whereType<Map<String, dynamic>>().map((it) {
      final original = (it['start_line'] as num?)?.toInt() ?? 0;
      final corrected =
          _correctedStartLine(original, it['anchor'] as String?, docLines);
      return (
        sectionType: (it['section_type'] as String?) ?? '',
        variantNumber: (it['variant_number'] as num?) ?? 0,
        versionLabel: it['version_label'] as String?,
        original: original,
        corrected: corrected,
      );
    }).toList();

    final byTarget = <String, List<int>>{};
    for (var i = 0; i < parsed.length; i++) {
      final p = parsed[i];
      byTarget
          .putIfAbsent('${p.sectionType}|${p.corrected}', () => [])
          .add(i);
    }

    return [
      for (var i = 0; i < parsed.length; i++)
        () {
          final p = parsed[i];
          final contenders = byTarget['${p.sectionType}|${p.corrected}']!;
          final winner = contenders.reduce((a, b) =>
              (parsed[a].original - parsed[a].corrected).abs() <=
                      (parsed[b].original - parsed[b].corrected).abs()
                  ? a
                  : b);
          final startLine = (contenders.length > 1 && i != winner)
              ? p.original
              : p.corrected;
          return DiscoveredItem(
            sectionType: p.sectionType,
            variantNumber: p.variantNumber,
            versionLabel: p.versionLabel,
            startLine: startLine,
          );
        }(),
    ];
  }

  /// Transcribing ~150-170 five-digit line numbers correctly per document
  /// is exactly the kind of narrow numeric task Gemini occasionally
  /// fumbles — confirmed live, twice, even at temperature=0 (Gemini's API
  /// doesn't guarantee bit-identical output across calls, greedy decoding
  /// or not): "start_line": 515 instead of the correct 9515, one dropped
  /// leading digit. Left uncorrected, that single wrong number plants a
  /// chunk boundary in a random, unrelated part of the document — this
  /// happened to land inside Lesen Teil 1's own content, truncating it,
  /// while also producing a garbage "Hören Teil 4" chunk out of reading-
  /// comprehension text.
  ///
  /// [anchor] is the model's own verbatim copy of the line at [startLine]
  /// (see prompts.py's discover instructions) — a second, independent
  /// signal that's cheap to cross-check against the actual document. A
  /// match means the number is trustworthy as-is. A mismatch searches the
  /// WHOLE document for the real line matching [anchor] and uses that
  /// instead — self-correcting a wrong digit instead of silently
  /// misplacing a section boundary. A dropped leading digit isn't a small
  /// offset (the live case, "515" instead of "9515", is 9000 lines off),
  /// so a bounded-radius search would miss it; documents only run to a
  /// few thousand lines, so a full scan costs nothing worth bounding for.
  /// The search expands outward from [startLine] (nearest match wins) so
  /// a short, coincidentally-common anchor still prefers the plausible
  /// nearby line over a distant lookalike. No match anywhere (anchor
  /// missing/garbled/too short to be a reliable needle) falls back to the
  /// model's original number rather than guessing further.
  @visibleForTesting
  int correctedStartLineForTest(
          int startLine, String? anchor, List<String> docLines) =>
      _correctedStartLine(startLine, anchor, docLines);

  // Collapsing internal whitespace runs to a single space absorbs the
  // model's own copying noise (extra/missing spaces around PDF-layout
  // artifacts like centered headings) without weakening the check's
  // ability to tell genuinely different lines apart — confirmed against
  // the real fixture: 4 of 6 apparent mismatches in one run were exactly
  // this (anchor had a stray extra space; the claimed start_line was
  // already correct), only 2 were real corruptions.
  String _normalizeForAnchorMatch(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ').trim();

  int _correctedStartLine(int startLine, String? anchor, List<String> docLines) {
    if (anchor == null || anchor.trim().length < 8) return startLine;
    final needle = _normalizeForAnchorMatch(anchor);
    if (startLine >= 0 &&
        startLine < docLines.length &&
        _normalizeForAnchorMatch(docLines[startLine]).contains(needle)) {
      return startLine;
    }
    for (var d = 1; d < docLines.length; d++) {
      final below = startLine - d;
      if (below >= 0 &&
          _normalizeForAnchorMatch(docLines[below]).contains(needle)) {
        return below;
      }
      final above = startLine + d;
      if (above < docLines.length &&
          _normalizeForAnchorMatch(docLines[above]).contains(needle)) {
        return above;
      }
      if (below < 0 && above >= docLines.length) break;
    }
    return startLine;
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
  Future<({List<dynamic> items, List<String> errors})> parseVariantGroups(
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
        final key = _cacheKey(
            'group', 'group|$sectionType|$text', _parseCacheVersion);
        final cached = await _cacheGet(key);
        if (cached != null) return cached as List<dynamic>;

        // A structurally malformed-but-valid-JSON result (dropped
        // question, empty transcript, ...) isn't a network fault, so
        // _parseWithRetry's own retry loop never sees it — retry here
        // instead. generationConfig runs at temperature=1, so a second
        // sample sometimes succeeds where the first one dropped content.
        // A source document with genuinely ambiguous/duplicated content
        // (two conflicting question sets for the same variant) will keep
        // failing every attempt — that's a real error worth surfacing,
        // not something a retry can paper over.
        List<String> lastProblems = const [];
        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            final parsed = await _parseWithRetry(text, sectionType);
            final expanded = _expandSentinels(parsed, sectionType);
            final problems = _validateGroup(expanded, sectionType);
            if (problems.isEmpty) {
              // Cache the EXPANDED result — every consumer (including
              // future cache hits) gets ready-to-use, fully
              // self-contained objects, so nothing downstream needs to
              // know sentinels ever existed.
              unawaited(_cacheSet(key, expanded));
              return expanded;
            }
            lastProblems = problems;
          } catch (e) {
            errors.add(e.toString());
            return const <dynamic>[];
          }
        }
        // Reject a malformed result rather than caching it — otherwise a
        // bad generation gets cached once and then silently re-served as
        // broken content on every future import of the same document,
        // with no way to self-heal short of bumping _parseCacheVersion for
        // everyone.
        errors.add('$sectionType variant ${g.variantNumber}: '
            '${lastProblems.join('; ')}');
        return const <dynamic>[];
      }));
      for (final r in settled) {
        results.addAll(r);
      }
      done += slice.length;
      onProgress?.call(done, groups.length);
    }

    // Everything failed → surface the error; partial success → keep results
    // AND report which variants were dropped, instead of silently shipping
    // a course with fewer variants than the document actually has.
    if (results.isEmpty && errors.isNotEmpty) {
      throw Exception(errors.first);
    }
    return (items: _mergeByVariant(results), errors: errors);
  }

  /// Sent by the prompt for a reworked edition's field that is word-for-
  /// word identical to the original variant's — saves Gemini from
  /// retyping large shared content (a reading passage, a dialogue
  /// transcript) in every edition. Expanded back to the real value here,
  /// right after parsing, so every consumer downstream (cache, storage,
  /// exercise screens) only ever sees complete, self-contained objects.
  static const _sameSentinel = '<<SAME_AS_ORIGINAL>>';

  /// Marks a field the source genuinely has no content for — never left
  /// empty (which validation can't tell apart from a dropped field) and
  /// never a fabricated guess. Originally telefonnotiz-only (an
  /// individual answer-key field, or an edition missing its whole
  /// monologue); also covers a whole question ("text"/"answer"/single
  /// "options" entry, see prompts.py's Common rules) when a numbered
  /// slot simply isn't printed for that edition — confirmed live on
  /// beschwerde variant 6's second edition, whose source ends before
  /// reaching questions 19/20 at all, which the model filled in with
  /// plausible-sounding but entirely invented options instead.
  static const _noAnswerSentinel = '(nicht angegeben)';

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

  bool _containsRaw(dynamic value, String needle) {
    if (value is String) return value.contains(needle);
    if (value is Map) return value.values.any((v) => _containsRaw(v, needle));
    if (value is List) return value.any((v) => _containsRaw(v, needle));
    return false;
  }

  /// Structural sanity checks run on every parsed object right after
  /// sentinel expansion, before it's ever cached or shown — catches the
  /// most common ways a generation goes wrong (dangling answer
  /// references, a dropped question_pairs entry, a leaked placeholder)
  /// so a bad result surfaces as a visible import error instead of being
  /// cached and silently re-served as broken content on every future
  /// import of the same document. Returns an empty list when the group
  /// looks structurally sound — this is a shape check, not a judge of
  /// whether the extracted text is actually correct.
  ///
  /// Test-only entry points below: the validated/expand/merge helpers are
  /// private (pure-function, no I/O) so a normal external test file can't
  /// call them directly — these thin wrappers expose just enough surface
  /// for `flutter test` without loosening real encapsulation or restating
  /// any logic.
  @visibleForTesting
  List<String> validateGroupForTest(List<dynamic> expanded, String sectionType) =>
      _validateGroup(expanded, sectionType);

  @visibleForTesting
  List<String> validateShapeForTest(
          String sectionType, Map<String, dynamic> item) =>
      _validateShape(sectionType, item);

  @visibleForTesting
  List<dynamic> expandSentinelsForTest(List<dynamic> group, String sectionType) =>
      _expandSentinels(group, sectionType);

  @visibleForTesting
  List<dynamic> mergeByVariantForTest(List<dynamic> raw) => _mergeByVariant(raw);

  List<String> _validateGroup(List<dynamic> expanded, String sectionType) {
    final problems = <String>[];
    // An empty array is "valid JSON" and passes every check below
    // vacuously (a for-loop over nothing finds no problems) — without
    // this, a call that gave up and returned [] silently drops the
    // whole variant from the course instead of surfacing as a failure.
    if (expanded.isEmpty) {
      return ['empty result — no variant object returned'];
    }
    for (final item in expanded) {
      if (item is! Map<String, dynamic>) {
        problems.add('non-object entry: $item');
        continue;
      }
      final leaks = _findSentinelPaths(item, '');
      if (leaks.isNotEmpty) {
        problems.add('unresolved <<SAME_AS_ORIGINAL>> at ${leaks.join(', ')}');
      }
      if (_containsRaw(item, itemDelimiter)) {
        problems.add('leaked $itemDelimiter delimiter');
      }
      if (item['variant_number'] == null) {
        problems.add('missing variant_number');
      }
      problems.addAll(_validateShape(sectionType, item));
    }
    return problems;
  }

  List<String> _validateShape(String sectionType, Map<String, dynamic> item) {
    return switch (sectionType) {
      'hoeren_teil1' => _validateHoerenTeil1(item),
      'telefonnotiz' => _validateTelefonnotiz(item),
      'sprachbausteine_teil1' => _validateSprachbausteine1(item),
      _ => _validateUniversal(sectionType, item),
    };
  }

  List<String> _validateHoerenTeil1(Map<String, dynamic> item) {
    final problems = <String>[];
    final pairs = item['question_pairs'];
    if (pairs is! List || pairs.length != 3) {
      problems.add('question_pairs must have exactly 3 entries, got '
          '${pairs is List ? pairs.length : 'none'}');
      return problems;
    }
    for (var i = 0; i < pairs.length; i++) {
      final pair = pairs[i];
      if (pair is! Map<String, dynamic>) {
        problems.add('question_pairs[$i] is not an object');
        continue;
      }
      final dialogue = pair['dialogue'];
      if (dialogue is! String || dialogue.trim().isEmpty) {
        problems.add('question_pairs[$i].dialogue is empty');
      }
      final rf = pair['richtig_falsch'];
      if (rf is! Map<String, dynamic> || rf['answer'] is! bool) {
        problems.add('question_pairs[$i].richtig_falsch missing/invalid answer');
      }
      final mc = pair['multiple_choice'];
      if (mc is! Map<String, dynamic>) {
        problems.add('question_pairs[$i].multiple_choice missing');
        continue;
      }
      final options = mc['options'];
      final correct = mc['correct_letter'];
      if (options is! List || options.isEmpty) {
        problems.add('question_pairs[$i].multiple_choice.options empty');
      } else if (correct is! String ||
          !options.any((o) => o is Map && o['letter'] == correct)) {
        problems.add('question_pairs[$i].multiple_choice.correct_letter '
            '"$correct" not among its own options');
      }
    }
    return problems;
  }

  List<String> _validateTelefonnotiz(Map<String, dynamic> item) {
    final problems = <String>[];
    final versions = item['versions'];
    if (versions is! List || versions.isEmpty) {
      problems.add('versions is empty');
      return problems;
    }
    for (var i = 0; i < versions.length; i++) {
      final v = versions[i];
      if (v is! Map<String, dynamic>) {
        problems.add('versions[$i] is not an object');
        continue;
      }
      // Same "(nicht angegeben)" vs. true emptiness distinction as the
      // answer fields below — an edition with no printed transcript is
      // a legitimate, non-empty value here, not a validation failure.
      final monologue = v['monologue'];
      if (monologue is! String || monologue.trim().isEmpty) {
        problems.add('versions[$i].monologue is empty');
      }
      final answer = v['answer'];
      if (answer is! Map<String, dynamic>) {
        problems.add('versions[$i].answer is missing');
        continue;
      }
      // All five fields come from a printed answer key, not free-form
      // generation — an empty one means Gemini missed a label on the
      // page, not that the field is genuinely blank. The UI silently
      // hides an empty field (SizedBox.shrink), so an unvalidated gap
      // here renders as a plausible-looking but incomplete answer card
      // instead of triggering a retry.
      //
      // A field that's genuinely blank in the source (e.g. a
      // "Telefonnummer:" line with nothing after it) is NOT the same
      // failure — the prompt tells Gemini to write the literal string
      // "(nicht angegeben)" for those instead of an empty string, so
      // this check (which only rejects true emptiness) already lets a
      // confirmed-blank field through without a pointless retry, while
      // still catching an accidentally dropped one.
      for (final field in const [
        'call_type',
        'name',
        'telefonnummer',
        'zu_erledigen',
      ]) {
        final value = answer[field];
        if (value is! String || value.trim().isEmpty) {
          problems.add('versions[$i].answer.$field is empty');
        }
      }
      final weitereInformationen = answer['weitere_informationen'];
      if (weitereInformationen is! List || weitereInformationen.isEmpty) {
        problems.add('versions[$i].answer.weitere_informationen is empty');
      }
    }
    return problems;
  }

  List<String> _validateSprachbausteine1(Map<String, dynamic> item) {
    final problems = <String>[];
    final letterText = item['letter_text'] as String?;
    if (letterText == null || letterText.trim().isEmpty) {
      problems.add('letter_text is empty');
    }
    final answers = item['answers'];
    if (answers is! List || answers.isEmpty) {
      problems.add('answers is empty');
      return problems;
    }
    final allOptions = item['all_options'];
    final optionLetters = allOptions is List
        ? allOptions.whereType<Map>().map((o) => o['letter']).toSet()
        : <dynamic>{};
    for (final a in answers) {
      if (a is! Map<String, dynamic>) continue;
      final letter = a['letter'];
      if (!optionLetters.contains(letter)) {
        problems.add('answers letter "$letter" (Q${a['question_number']}) '
            'not among all_options');
      }
      final num = a['question_number'];
      if (letterText != null && !letterText.contains('[$num]')) {
        problems.add('letter_text missing [$num] marker');
      }
    }
    return problems;
  }

  /// Every telc B2 Beruf section has a fixed official question count,
  /// independent of which document it was extracted from — a Hören Teil 3
  /// variant always has exactly 4 questions (32-35), whether it came from
  /// this PDF or any other. A short count means Gemini silently dropped
  /// questions (or the transcript ran out mid-item), not that this
  /// particular variant is legitimately shorter.
  static const _expectedQuestionCount = <String, int>{
    'lesen_teil1': 5,
    'lesen_teil2': 2,
    'lesen_teil3': 4,
    'lesen_teil4': 5,
    'beschwerde': 2,
    'sprachbausteine_teil2': 6,
    'hoeren_teil2': 4,
    'hoeren_teil3': 4,
    // Confirmed against telc's own official B2 Beruf test-format table:
    // 5 Multiple-Choice-Aufgaben, not 8 — the old value was simply wrong,
    // not "usually 8 with occasional shorter variants".
    'hoeren_teil4': 5,
  };

  /// Covers every section using the shared universal schema (lesen_teil1-4,
  /// hoeren_teil2-4, beschwerde, sprachbausteine_teil2).
  List<String> _validateUniversal(String sectionType, Map<String, dynamic> item) {
    final problems = <String>[];
    final texts = item['texts'];
    if (texts is! List || texts.isEmpty) {
      problems.add('texts is empty — reading passage/transcript is missing');
    }
    final questions = item['questions'];
    if (questions is! List || questions.isEmpty) {
      problems.add('questions is empty');
      return problems;
    }
    final expected = _expectedQuestionCount[sectionType];
    if (expected != null && questions.length != expected) {
      problems.add('expected $expected questions for $sectionType, '
          'got ${questions.length}');
    }
    final poolLetters = (item['option_pool'] as List?)
            ?.whereType<Map>()
            .map((o) => o['letter'])
            .toSet() ??
        <dynamic>{};
    for (final q in questions) {
      if (q is! Map<String, dynamic>) {
        problems.add('a question entry is not an object');
        continue;
      }
      final type = q['type'];
      final answer = q['answer'];
      // A question the source genuinely never printed for this edition
      // (see prompts.py's Common rules) — the model is instructed to say
      // so honestly rather than invent a plausible-looking answer, so an
      // answer that can't be matched to any option/pool entry/richtig-
      // falsch is expected here, not a parsing failure to retry over.
      if (answer == _noAnswerSentinel) continue;
      switch (type) {
        case 'match':
          if (!poolLetters.contains(answer)) {
            problems.add('question ${q['number']}: match answer "$answer" '
                'not in option_pool');
          }
        case 'choice':
          final options = q['options'];
          final letters = options is List
              ? options.whereType<Map>().map((o) => o['letter']).toSet()
              : <dynamic>{};
          if (!letters.contains(answer)) {
            problems.add('question ${q['number']}: choice answer "$answer" '
                'not among its own options');
          }
        case 'true_false':
          if (answer != 'richtig' && answer != 'falsch') {
            problems.add('question ${q['number']}: true_false answer '
                '"$answer" is not richtig/falsch');
          }
        default:
          problems.add('question ${q['number']}: unknown type "$type"');
      }
    }
    return problems;
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

  Future<List<dynamic>> _parseWithRetry(String markdown, String sectionType,
      {Duration? timeout}) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await parseSection(markdown, sectionType, timeout: timeout);
      } catch (e) {
        lastError = e;
        // 400/401/403 are rejections by policy (bad request, unauthenticated,
        // tier/quota gate — e.g. free tier hitting a document that needs a
        // fresh Premium discover, or a daily import cap) — retrying can
        // never turn one of these into success, only delay the user seeing
        // why it failed by several seconds for nothing. 429 (Gemini's own
        // rate limit) is the one 4xx worth waiting out; everything else
        // 4xx fails fast.
        // Anchored to parseSection's own message prefix ('Ошибка парсинга
        // <code>: <body>') rather than searching the whole string — the
        // body is server-controlled response text and could coincidentally
        // contain a "400"/"401"/"403"-looking substring of its own.
        final message = e.toString();
        final statusMatch =
            RegExp(r'^Exception: Ошибка парсинга (\d+):').firstMatch(message);
        final status = statusMatch != null ? int.tryParse(statusMatch.group(1)!) : null;
        if (status == 400 || status == 401 || status == 403) break;
        final seconds = status == 429 ? 15 : 2 + attempt * 3;
        await Future.delayed(Duration(seconds: seconds));
      }
    }
    throw Exception(lastError.toString());
  }
}
