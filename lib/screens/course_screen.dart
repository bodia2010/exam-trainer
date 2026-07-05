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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await CourseStorage.instance.loadAll();
      final course = all.where((c) => c.id == widget.id).firstOrNull;
      if (mounted) {
        setState(() {
          _course = course;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course?.title ?? '',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Prüfungsteile',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : course == null
              ? const Center(child: Text('Курс не найден'))
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
    final available = sectionMeta.entries
        .where((e) => (course.sections[e.key] ?? []).isNotEmpty)
        .toList();

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: available.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final type = available[i].key;
          final meta = available[i].value;
          final count = course.sections[type]!.length;
          return _TeilCard(
            eyebrow: meta.label,
            title: meta.taskName,
            description: '$count вариантов',
            icon: meta.icon,
            color: meta.color,
            onTap: () => context.push('/course/${course.id}/$type'),
          );
        },
      ),
    );
  }
}

class _TeilCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TeilCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style:
                          TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
