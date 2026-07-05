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

  Future<void> _runImport(List<int> bytes, String filename) async {
    final pdfBytes = Uint8List.fromList(bytes);

    setState(() => _status = 'Конвертация PDF…');
    final markdown = await ParseService.instance.convertPdf(pdfBytes);

    final sectionTypes = {
      'hoeren_teil1':          'Hören Teil 1',
      'hoeren_teil2':          'Hören Teil 2',
      'telefonnotiz':          'Telefonnotiz',
      'sprachbausteine_teil1': 'Sprachbausteine Teil 1',
    };

    final sections = <String, List<dynamic>>{};
    var i = 0;
    for (final entry in sectionTypes.entries) {
      i++;
      setState(() => _status = 'Разбор разделов… ${entry.value} ($i/${sectionTypes.length})');
      try {
        final chunk = ParseService.instance.extractSection(markdown, entry.value);
        if (chunk.isNotEmpty) {
          final result = await ParseService.instance.parseSection(chunk, entry.key);
          sections[entry.key] = result;
          debugPrint('[parse] ${entry.key}: ${result.length} variants');
        } else {
          debugPrint('[parse] ${entry.key}: section not found in markdown');
          sections[entry.key] = [];
        }
      } catch (e) {
        debugPrint('[parse] ${entry.key} ERROR: $e');
        sections[entry.key] = [];
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
          'Например, файл из вашей Telegram-группы\nс вариантами telc B2 Beruf',
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
        const Text('Это может занять 1–2 минуты',
            style: TextStyle(color: Color(0xFF757575), fontSize: 13)),
      ],
    );
  }
}
