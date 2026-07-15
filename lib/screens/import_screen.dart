import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../l10n/strings.dart';
import '../models/parsed_course.dart';
import '../services/parse_service.dart';
import '../services/course_storage.dart';
import '../ui/core/theme/exam_theme.dart';
import 'exam_profile_screen.dart';

/// Converts a premium-populated whole-document cache entry into the exact
/// subset available on the free tier: one top-level variant per section and,
/// for telefonnotiz, one nested edition inside that variant.
Map<String, List<dynamic>> freeTierSectionsFromCache(
  Map<String, List<dynamic>> cached,
) {
  return cached.map((type, items) {
    if (items.isEmpty || items.first is! Map) {
      return MapEntry(type, const <dynamic>[]);
    }
    final first = Map<String, dynamic>.from(items.first as Map);
    return MapEntry(type, <dynamic>[freeTierTrimmed(first, type)]);
  });
}

Map<String, dynamic> freeTierTrimmed(Map<String, dynamic> item, String type) {
  if (type != 'telefonnotiz') return item;
  final versions = item['versions'];
  if (versions is! List || versions.length <= 1) return item;
  return {
    ...item,
    'versions': [versions.first],
  };
}

class ImportScreen extends StatefulWidget {
  final ExamProfile? profile;
  const ImportScreen({super.key, this.profile});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _importing = false;
  String _status = '';
  String? _error;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;
    final filename = result.files.single.name;
    setState(() {
      _importing = true;
      _error = null;
    });

    try {
      await _runImport(bytes, filename);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _importing = false;
        });
      }
    }
  }

  // Fixed display order — the document's own order (from discovery) is
  // used for merging/slicing, but progress messages read better in a
  // consistent, predictable sequence.
  static const _sectionOrder = [
    'lesen_teil1',
    'lesen_teil2',
    'lesen_teil3',
    'lesen_teil4',
    'beschwerde',
    'sprachbausteine_teil1',
    'sprachbausteine_teil2',
    'telefonnotiz',
    'hoeren_teil1',
    'hoeren_teil2',
    'hoeren_teil3',
    'hoeren_teil4',
  ];

  Future<void> _runImport(List<int> bytes, String filename) async {
    final s = S.of(context);
    final pdfBytes = Uint8List.fromList(bytes);

    setState(() => _status = s.pdfKonvertierung);
    final markdown = await ParseService.instance.convertPdf(pdfBytes);

    final isPremium = await ParseService.instance.isPremium();

    final sections = <String, List<dynamic>>{};
    final sectionErrors = <String, String>{};

    // Premium imports populate the shared whole-document cache. Free users
    // may open those already-processed documents, but only after the cached
    // result is reduced to the same first-variant/first-edition view they
    // would receive from the normal free-tier parsing path.
    setState(() => _status = s.cachePruefung);
    final cached = await ParseService.instance.getCachedSections(markdown);

    if (cached != null) {
      sections.addAll(isPremium ? cached : freeTierSectionsFromCache(cached));
      debugPrint('[parse] cache hit — skipped discovery + parsing');
    } else {
      // AI scans the whole document once and finds every exercise by its
      // structure (not a hardcoded literal label) — works for PDFs that
      // don't match this app's original reference format.
      setState(() => _status = s.dokumentstrukturAnalyse);
      final discovered = await ParseService.instance.discoverSections(markdown);
      final groupsByType = ParseService.instance.groupChunksBySectionType(
        markdown,
        discovered,
      );

      if (groupsByType.isEmpty) {
        sectionErrors['PDF'] = s.keinUebungErkannt;
      }

      // 'other' chunks are expected (tables of contents, link-only pages,
      // meta-commentary) and never parsed — but discovery has been known
      // to mis-flag a mid-variant marker (e.g. a single-question answer
      // correction) as an 'other' boundary, silently truncating a real
      // section's content with no error shown anywhere. A short 'other'
      // chunk is normal filler; a large one is exactly what a swallowed
      // exercise chunk looks like, so it's worth a loud signal even
      // though it isn't surfaced to the user as an import error (a false
      // positive here would incorrectly block otherwise-fine imports).
      final otherChars =
          groupsByType['other']
              ?.expand((g) => g.chunks)
              .fold<int>(0, (sum, c) => sum + c.length) ??
          0;
      if (otherChars > 500) {
        debugPrint(
          '[parse] suspiciously large "other" bucket: '
          '$otherChars chars — check for a mis-flagged mid-section '
          'boundary in discovery output',
        );
      }

      final presentTypes = _sectionOrder
          .where((t) => groupsByType.containsKey(t))
          .toList();

      var i = 0;
      for (final type in presentTypes) {
        i++;
        final label = sectionLabels[type] ?? type;
        // Free tier: only the first variant of each section, and only its
        // ORIGINAL chunk — no reworked editions at all. Editions exist as
        // a separate concept purely because the group they came in also
        // had the original; sending just one chunk gives the model
        // nothing to build a "version" out of, which is a much simpler
        // guarantee than trying to filter versions back out afterwards.
        final allGroups = groupsByType[type]!;
        final groups = isPremium
            ? allGroups
            : [
                VariantGroup(
                  variantNumber: allGroups.first.variantNumber,
                  chunks: [allGroups.first.chunks.first],
                ),
              ];
        setState(
          () => _status = s.abschnitteAnalyse(label, i, presentTypes.length),
        );
        try {
          final result = await ParseService.instance.parseVariantGroups(
            groups,
            type,
            onProgress: (done, total) {
              if (mounted && total > 1) {
                setState(
                  () => _status =
                      s.abschnitteAnalyse(label, i, presentTypes.length) +
                      s.variantePart(done, total),
                );
              }
            },
          );
          // Free tier only ever sent ONE chunk (the original), so
          // there's exactly one possible source of truth for what comes
          // back — no need to gate on Gemini echoing the right
          // variant_number/version, which turned out unreliable enough
          // to silently drop the whole section (matched on version,
          // then on variant_number, both dropped real content with no
          // error at all). Take the one object it returned and STAMP
          // the variant_number we already know is correct onto it,
          // rather than trust-but-verify an echo that doesn't need to
          // exist in the first place.
          final filtered = isPremium
              ? result.items
              : (result.items.isEmpty
                    ? const <dynamic>[]
                    : [
                        freeTierTrimmed({
                          ...(result.items.first as Map<String, dynamic>),
                          'variant_number': groups.first.variantNumber,
                        }, type),
                      ]);
          sections[type] = filtered;
          debugPrint(
            '[parse] $type: ${filtered.length}/${result.items.length} '
            'variants kept (${groups.length}/${allGroups.length} groups)',
          );
          // Some groups failed validation/parsing but at least one
          // succeeded — the section still has content, but silently
          // dropping the bad variant(s) would hide that the course is
          // now missing something the PDF actually contains.
          if (result.errors.isNotEmpty) {
            sectionErrors[label] = result.errors.join('\n');
          }
        } catch (e) {
          debugPrint('[parse] $type ERROR: $e');
          sections[type] = [];
          sectionErrors[label] = e.toString();
        }
      }

      // Best-effort: don't block the user on this, and a failed section
      // shouldn't poison the cache with an incomplete course.
      if (isPremium && sectionErrors.isEmpty && sections.isNotEmpty) {
        unawaited(ParseService.instance.cacheSections(markdown, sections));
      }
    }

    setState(() => _status = s.speichern);
    final profile = widget.profile;
    final course = ParsedCourse(
      id: const Uuid().v4(),
      title: filename.replaceAll('.pdf', ''),
      sourceFilename: filename,
      parsedAt: DateTime.now(),
      sections: sections,
      examProvider: profile?.provider ?? 'telc',
      examCourseType: profile?.courseType ?? 'Beruf',
      examLevel: profile?.level ?? 'B2',
    );
    await CourseStorage.instance.save(course);

    if (!mounted) return;

    if (sectionErrors.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(s.mancheAbschnitteFehler),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sectionErrors.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(e.value, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.verstanden),
            ),
          ],
        ),
      );
    }

    // Swap this screen for the course screen in place (Home stays right
    // where it was underneath) — Home no longer needs a forced rebuild to
    // pick up the new course, it listens to CourseStorage's revision
    // counter and reloads on its own. A previous go('/') + push(...)
    // combo tried to force a fresh Home instance instead, but firing both
    // calls back-to-back without awaiting go()'s async transition left a
    // stale, frozen ImportScreen stuck in the stack under the course
    // screen — visible as an infinite "Speichern…" spinner one back-tap
    // away from Home.
    if (mounted) {
      context.pushReplacement('/course/${course.id}');
    }
  }

  /// The free-tier restriction above assumes one top-level parsed object
  /// == one edition, true for every section type EXCEPT telefonnotiz,
  /// whose editions ("Старый вариант" / "Новый вариант от `<date>`") are
  /// nested inside a single object's own "versions" list instead of being
  /// separate top-level objects (see TELEFONNOTIZ_SCHEMA in
  /// response_schemas.py). Discovery is supposed to still split those
  /// into separate chunks so the free-tier's chunks.first cuts it down to
  /// one edition before the content ever reaches Gemini — but that's not
  /// guaranteed (observed live: both editions landed in the same
  /// discovered chunk, so Gemini legitimately found both inside it and
  /// the free-tier user saw a version switcher it shouldn't have). Trim
  /// defensively at the output too, not just the input, so this can't
  /// silently regress again if discovery's chunking behavior drifts.
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: ExamColors.canvas,
      appBar: AppBar(
        backgroundColor: ExamColors.canvas,
        foregroundColor: ExamColors.ink,
        title: Text(s.importPdf),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ExamSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ExamColors.surface,
                borderRadius: BorderRadius.circular(ExamRadius.large),
                border: Border.all(color: ExamColors.border),
                boxShadow: [
                  BoxShadow(
                    color: ExamColors.ink.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(ExamSpacing.xl),
                child: _importing ? _progress(s) : _picker(s),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _picker(S s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: ExamColors.tealSoft,
            borderRadius: BorderRadius.circular(ExamRadius.large),
          ),
          child: const Icon(
            Icons.upload_file_rounded,
            size: 48,
            color: ExamColors.teal,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          s.pdfMitUebungenWaehlen,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ExamColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.importPickerHint,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ExamColors.inkMuted, height: 1.45),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ExamColors.coralSoft,
              borderRadius: BorderRadius.circular(ExamRadius.medium),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: ExamColors.danger, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ExamColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ExamRadius.medium),
              ),
            ),
            onPressed: _pick,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(s.pdfWaehlen, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _progress(S s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: ExamColors.teal),
        const SizedBox(height: 24),
        Text(
          _status,
          style: const TextStyle(color: ExamColors.ink, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          s.vollstaendigeAnalyseDauer,
          style: const TextStyle(color: ExamColors.inkMuted, fontSize: 13),
        ),
      ],
    );
  }
}
