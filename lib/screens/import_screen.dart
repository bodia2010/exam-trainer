import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../l10n/strings.dart';
import '../models/parsed_course.dart';
import '../services/api_exception.dart';
import '../services/parse_service.dart';
import '../ui/core/theme/exam_theme.dart';
import '../ui/features/import/pdf_import_controller.dart';
import '../ui/features/import/pdf_import_file.dart';
import '../ui/features/import/pdf_import_services.dart';
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
  final PdfFilePicker filePicker;
  final PdfFileValidator fileValidator;
  final PdfImportServices services;

  const ImportScreen({
    super.key,
    this.profile,
    this.filePicker = const PlatformPdfFilePicker(),
    this.fileValidator = const PdfFileValidator(),
    this.services = const ProductionPdfImportServices(),
  });

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late final PdfImportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfImportController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final operationId = _controller.start();
    try {
      final picked = await widget.filePicker.pick();
      if (!_isActive(operationId)) return;
      if (picked == null) {
        _controller.reset(operationId);
        return;
      }
      _controller.update(operationId, PdfImportPhase.validating);
      final file = await widget.fileValidator.validate(picked);
      if (!_isActive(operationId)) return;
      await _runImport(operationId, file);
    } on PdfFileValidationException catch (error) {
      _controller.fail(operationId, _validationMessage(error.error));
    } on ApiException catch (error) {
      _controller.fail(operationId, _apiErrorMessage(error));
    } catch (_) {
      _controller.fail(operationId, _genericImportError());
    }
  }

  /// Distinct, actionable copy per backend failure kind (CR-11) instead of
  /// always showing the same generic retry message — [ApiException] never
  /// carries the raw response body this could otherwise leak.
  String _apiErrorMessage(ApiException error) {
    final s = S.of(context);
    return switch (error.kind) {
      ApiErrorKind.unauthorized => s.importFehlerSitzungAbgelaufen,
      ApiErrorKind.forbidden => s.importFehlerPremiumErforderlich,
      ApiErrorKind.payloadTooLarge => s.importFehlerDateiZuGross,
      ApiErrorKind.rateLimited => s.importFehlerRateLimit,
      ApiErrorKind.networkOrTimeout => s.importFehlerVerbindung,
      ApiErrorKind.serverError || ApiErrorKind.unknown => _genericImportError(),
    };
  }

  bool _isActive(int operationId) =>
      mounted && _controller.isCurrent(operationId);

  String _validationMessage(PdfFileValidationError error) {
    final language = Localizations.localeOf(context).languageCode;
    return switch ((language, error)) {
      ('ru', PdfFileValidationError.tooLarge) =>
        'PDF слишком большой. Максимальный размер — 25 МБ.',
      ('uk', PdfFileValidationError.tooLarge) =>
        'PDF завеликий. Максимальний розмір — 25 МБ.',
      ('en', PdfFileValidationError.tooLarge) =>
        'The PDF is too large. The maximum size is 25 MB.',
      (_, PdfFileValidationError.tooLarge) =>
        'Das PDF ist zu groß. Die maximale Größe beträgt 25 MB.',
      ('ru', PdfFileValidationError.invalidSignature) =>
        'Выбранный файл не является корректным PDF.',
      ('uk', PdfFileValidationError.invalidSignature) =>
        'Вибраний файл не є коректним PDF.',
      ('en', PdfFileValidationError.invalidSignature) =>
        'The selected file is not a valid PDF.',
      (_, PdfFileValidationError.invalidSignature) =>
        'Die ausgewählte Datei ist kein gültiges PDF.',
      ('ru', PdfFileValidationError.inaccessible) =>
        'Не удалось прочитать выбранный файл.',
      ('uk', PdfFileValidationError.inaccessible) =>
        'Не вдалося прочитати вибраний файл.',
      ('en', PdfFileValidationError.inaccessible) =>
        'The selected file could not be read.',
      (_, PdfFileValidationError.inaccessible) =>
        'Die ausgewählte Datei konnte nicht gelesen werden.',
    };
  }

  String _genericImportError() {
    final language = Localizations.localeOf(context).languageCode;
    return switch (language) {
      'ru' => 'Не удалось импортировать PDF. Попробуйте ещё раз.',
      'uk' => 'Не вдалося імпортувати PDF. Спробуйте ще раз.',
      'en' => 'The PDF could not be imported. Please try again.',
      _ =>
        'Das PDF konnte nicht importiert werden. Bitte versuchen Sie es erneut.',
    };
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

  Future<void> _runImport(int operationId, ValidatedPdfFile file) async {
    final s = S.of(context);
    _controller.update(
      operationId,
      PdfImportPhase.converting,
      status: s.pdfKonvertierung,
    );
    final markdown = await widget.services.convertPdf(file);
    if (!_isActive(operationId)) return;

    final isPremium = await widget.services.isPremium();
    if (!_isActive(operationId)) return;

    final sections = <String, List<dynamic>>{};
    final sectionErrors = <String, String>{};

    // Premium imports populate the shared whole-document cache. Free users
    // may open those already-processed documents, but only after the cached
    // result is reduced to the same first-variant/first-edition view they
    // would receive from the normal free-tier parsing path.
    _controller.update(
      operationId,
      PdfImportPhase.processing,
      status: s.cachePruefung,
    );
    final cached = await widget.services.getCachedSections(markdown);
    if (!_isActive(operationId)) return;

    if (cached != null) {
      sections.addAll(isPremium ? cached : freeTierSectionsFromCache(cached));
      debugPrint('[parse] cache hit — skipped discovery + parsing');
    } else {
      // AI scans the whole document once and finds every exercise by its
      // structure (not a hardcoded literal label) — works for PDFs that
      // don't match this app's original reference format.
      _controller.update(
        operationId,
        PdfImportPhase.processing,
        status: s.dokumentstrukturAnalyse,
      );
      final discovered = await widget.services.discoverSections(markdown);
      if (!_isActive(operationId)) return;
      final groupsByType = widget.services.groupChunksBySectionType(
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
        _controller.update(
          operationId,
          PdfImportPhase.processing,
          status: s.abschnitteAnalyse(label, i, presentTypes.length),
        );
        try {
          final result = await widget.services.parseVariantGroups(
            groups,
            type,
            onProgress: (done, total) {
              if (_isActive(operationId) && total > 1) {
                _controller.update(
                  operationId,
                  PdfImportPhase.processing,
                  status:
                      s.abschnitteAnalyse(label, i, presentTypes.length) +
                      s.variantePart(done, total),
                );
              }
            },
          );
          if (!_isActive(operationId)) return;
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
            sectionErrors[label] = s.keinUebungErkannt;
          }
        } catch (error, stackTrace) {
          debugPrint('[parse] $type ERROR: $error\n$stackTrace');
          sections[type] = [];
          sectionErrors[label] = s.keinUebungErkannt;
        }
      }

      // Best-effort: don't block the user on this, and a failed section
      // shouldn't poison the cache with an incomplete course.
      if (isPremium && sectionErrors.isEmpty && sections.isNotEmpty) {
        unawaited(widget.services.cacheSections(markdown, sections));
      }
    }

    if (!_isActive(operationId)) return;
    _controller.update(operationId, PdfImportPhase.saving, status: s.speichern);
    final profile = widget.profile;
    final course = ParsedCourse(
      id: const Uuid().v4(),
      title: file.name.replaceFirst(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      ),
      sourceFilename: file.name,
      parsedAt: DateTime.now(),
      sections: sections,
      examProvider: profile?.provider ?? 'telc',
      examCourseType: profile?.courseType ?? 'Beruf',
      examLevel: profile?.level ?? 'B2',
    );
    // Cancellation is cooperative because the current backend has no import
    // job/cancel endpoint. Crucially, no local user data is written once this
    // operation has become stale or the screen has gone away.
    if (!_isActive(operationId)) return;
    await widget.services.saveCourse(course);

    if (!_isActive(operationId)) return;

    if (sectionErrors.isNotEmpty) {
      if (!mounted) return;
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
      if (!_isActive(operationId)) return;
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
    if (!_isActive(operationId)) return;
    if (!mounted) return;
    _controller.succeed(operationId);
    context.pushReplacement('/course/${course.id}');
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
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
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
                    child: state.isRunning
                        ? _progress(s, state.status)
                        : _picker(s, state.error),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _picker(S s, String? error) {
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
        if (error != null) ...[
          const SizedBox(height: 16),
          Container(
            key: const Key('import-pdf-error'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ExamColors.coralSoft,
              borderRadius: BorderRadius.circular(ExamRadius.medium),
            ),
            child: Text(
              error,
              style: const TextStyle(color: ExamColors.danger, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('import-pdf-picker'),
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

  Widget _progress(S s, String status) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: ExamColors.teal),
        const SizedBox(height: 24),
        Text(
          status,
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
