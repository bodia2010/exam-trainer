import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/parsed_course.dart';
import '../services/parse_service.dart';
import '../services/course_storage.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

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
    setState(() { _importing = true; _error = null; });

    try {
      await _runImport(bytes, filename);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _importing = false; });
    }
  }

  // Fixed display order — the document's own order (from discovery) is
  // used for merging/slicing, but progress messages read better in a
  // consistent, predictable sequence.
  static const _sectionOrder = [
    'lesen_teil1', 'lesen_teil2', 'lesen_teil3', 'lesen_teil4',
    'beschwerde', 'sprachbausteine_teil1', 'sprachbausteine_teil2',
    'telefonnotiz', 'hoeren_teil1', 'hoeren_teil2', 'hoeren_teil3', 'hoeren_teil4',
  ];

  Future<void> _runImport(List<int> bytes, String filename) async {
    final pdfBytes = Uint8List.fromList(bytes);

    setState(() => _status = 'Конвертация PDF…');
    final markdown = await ParseService.instance.convertPdf(pdfBytes);

    // AI scans the whole document once and finds every exercise by its
    // structure (not a hardcoded literal label) — works for PDFs that
    // don't match this app's original reference format.
    setState(() => _status = 'Анализ структуры документа…');
    final discovered = await ParseService.instance.discoverSections(markdown);
    final chunksByType =
        ParseService.instance.chunksBySectionType(markdown, discovered);

    final sections = <String, List<dynamic>>{};
    final sectionErrors = <String, String>{};

    if (chunksByType.isEmpty) {
      sectionErrors['PDF'] =
          'В этом файле не удалось распознать ни одного упражнения.';
    }

    final presentTypes =
        _sectionOrder.where((t) => chunksByType.containsKey(t)).toList();

    var i = 0;
    for (final type in presentTypes) {
      i++;
      final label = sectionLabels[type] ?? type;
      final chunks = chunksByType[type]!;
      setState(() =>
          _status = 'Разбор разделов… $label ($i/${presentTypes.length})');
      try {
        final result = await ParseService.instance.parseChunksInBatches(
          chunks,
          type,
          onProgress: (done, total) {
            if (mounted && total > 1) {
              setState(() => _status =
                  'Разбор разделов… $label ($i/${presentTypes.length})\nчасть $done из $total');
            }
          },
        );
        sections[type] = result;
        debugPrint(
            '[parse] $type: ${result.length} variants (${chunks.length} found)');
      } catch (e) {
        debugPrint('[parse] $type ERROR: $e');
        sections[type] = [];
        sectionErrors[label] = e.toString();
      }
    }

    setState(() => _status = 'Сохранение…');
    final course = ParsedCourse(
      id: const Uuid().v4(),
      title: filename.replaceAll('.pdf', ''),
      sourceFilename: filename,
      parsedAt: DateTime.now(),
      sections: sections,
    );
    await CourseStorage.instance.save(course);

    if (!mounted) return;

    if (sectionErrors.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Некоторые разделы не удалось разобрать'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sectionErrors.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.key,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(e.value, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
    }

    if (mounted) context.go('/course/${course.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        title: const Text('Импорт PDF'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _importing ? _progress() : _picker(),
        ),
      ),
    );
  }

  Widget _picker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.picture_as_pdf_outlined, size: 80, color: Color(0xFF00838F)),
        const SizedBox(height: 24),
        const Text('Выберите PDF с упражнениями',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          'telc B2 Beruf — Lesen, Hören, Sprachbausteine,\n'
          'Beschwerde, Telefonnotiz. ИИ сам находит разделы,\n'
          'даже если PDF оформлен иначе, чем обычно.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF757575)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13)),
          ),
        ],
        const SizedBox(height: 32),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00838F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _pick,
          icon: const Icon(Icons.upload_file),
          label: const Text('Выбрать PDF', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _progress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Color(0xFF00838F)),
        const SizedBox(height: 24),
        Text(_status,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Полный разбор занимает 5–10 минут',
            style: TextStyle(color: Color(0xFF757575), fontSize: 13)),
      ],
    );
  }
}
