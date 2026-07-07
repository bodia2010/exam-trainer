import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/parsed_course.dart';
import '../services/course_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ParsedCourse> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final courses = await CourseStorage.instance.loadAll();
      if (mounted) setState(() { _courses = courses; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete(ParsedCourse course) async {
    await CourseStorage.instance.delete(course.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text('Willkommen',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text('Exam Trainer',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A237E),
                            letterSpacing: -0.5)),
                    const SizedBox(height: 28),
                    _buildHeroCard(context),
                    const SizedBox(height: 28),
                    const Text('Übungsbereiche',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E))),
                    const SizedBox(height: 14),
                    _QuickCard(
                      label: 'Mündliche Prüfung',
                      subtitle: 'B2 Beruf · Teil 1–3',
                      icon: Icons.record_voice_over_rounded,
                      color: const Color(0xFF6A1B9A),
                      onTap: () => context.push('/sprechen'),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Text('Meine Kurse',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A237E))),
                        const Spacer(),
                        if (_courses.isNotEmpty)
                          Text('${_courses.length}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_courses.isEmpty) _buildEmptyCourses(context) else _buildCourseList(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('EIGENES PDF',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 16),
                const Text('Prüfung mit\neigenem Material üben',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 8),
                Text('Laden Sie ein PDF hoch — der Rest ist automatisch.',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.push('/import'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file, color: Color(0xFF1A237E), size: 18),
                        SizedBox(width: 8),
                        Text('PDF importieren',
                            style: TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCourses(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 56, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 12),
          const Text('Нет импортированных курсов',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575))),
        ],
      ),
    );
  }

  Widget _buildCourseList(BuildContext context) {
    return Column(
      children: [
        for (final course in _courses) ...[
          _QuickCard(
            label: course.title,
            subtitle:
                '${course.sections.values.fold(0, (s, v) => s + v.length)} вариантов · ${_formatDate(course.parsedAt)}',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF00838F),
            onTap: () => context.push('/course/${course.id}'),
            onLongPress: () => _confirmDelete(context, course),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _confirmDelete(BuildContext context, ParsedCourse course) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить курс?'),
        content: Text(course.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () { Navigator.pop(context); _delete(course); },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _QuickCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _QuickCard({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
