import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/parsed_course.dart' show ParsedCourse, sectionLabels;
import '../services/course_storage.dart';

class SectionListScreen extends StatefulWidget {
  final String courseId;
  final String sectionType;
  const SectionListScreen({
    super.key,
    required this.courseId,
    required this.sectionType,
  });

  @override
  State<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends State<SectionListScreen> {
  List<dynamic> _variants = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await CourseStorage.instance.loadAll();
    final course = all.where((c) => c.id == widget.courseId).firstOrNull;
    if (course != null && mounted) {
      setState(() => _variants = course.sections[widget.sectionType] ?? []);
    }
  }

  String get _title => sectionLabels[widget.sectionType] ?? widget.sectionType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        title: Text(_title),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _variants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final v = _variants[i] as Map<String, dynamic>;
          final num = v['variant_number'] ?? (i + 1);
          final topic = v['topic'] as String? ?? '';
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00838F),
                child: Text('$num',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text('Вариант $num',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: topic.isNotEmpty ? Text(topic) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                  '/course/${widget.courseId}/${widget.sectionType}/$i'),
            ),
          );
        },
      ),
    );
  }
}
