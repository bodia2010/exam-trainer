import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/parsed_course.dart';
import '../services/course_storage.dart';

class CourseScreen extends StatefulWidget {
  final String id;
  const CourseScreen({super.key, required this.id});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  ParsedCourse? _course;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await CourseStorage.instance.loadAll();
    final course = all.where((c) => c.id == widget.id).firstOrNull;
    if (mounted) setState(() => _course = course);
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        title: Text(course?.title ?? ''),
        elevation: 0,
      ),
      body: course == null
          ? const Center(child: CircularProgressIndicator())
          : _sections(context, course),
      bottomNavigationBar: course != null &&
              course.sections.values.every((v) => v.isEmpty)
          ? Container(
              color: const Color(0xFFFFEBEE),
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Разделы не распознаны. Попробуйте импортировать PDF ещё раз.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
              ),
            )
          : null,
    );
  }

  Widget _sections(BuildContext context, ParsedCourse course) {
    final sections = [
      ('lesen_teil1',           'Lesen Teil 1',           Icons.menu_book),
      ('lesen_teil2',           'Lesen Teil 2',           Icons.menu_book),
      ('lesen_teil3',           'Lesen Teil 3',           Icons.menu_book),
      ('lesen_teil4',           'Lesen Teil 4',           Icons.menu_book),
      ('beschwerde',            'Beschwerde',             Icons.mail_outline),
      ('sprachbausteine_teil1', 'Sprachbausteine Teil 1', Icons.spellcheck),
      ('sprachbausteine_teil2', 'Sprachbausteine Teil 2', Icons.spellcheck),
      ('telefonnotiz',          'Hören + Schreiben',      Icons.phone),
      ('hoeren_teil1',          'Hören Teil 1',           Icons.headphones),
      ('hoeren_teil2',          'Hören Teil 2',           Icons.headphones),
      ('hoeren_teil3',          'Hören Teil 3',           Icons.headphones),
      ('hoeren_teil4',          'Hören Teil 4',           Icons.headphones),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (type, label, icon) = sections[i];
        final variants = course.sections[type] ?? [];
        if (variants.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE0F7FA),
              child: Icon(icon, color: const Color(0xFF00838F)),
            ),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${variants.length} вариантов',
                style: const TextStyle(color: Color(0xFF757575))),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/course/${course.id}/$type'),
          ),
        );
      },
    );
  }
}
