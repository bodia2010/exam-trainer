import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/strings.dart';
import '../models/parsed_course.dart';
import '../services/course_storage.dart';
import '../ui/core/theme/exam_theme.dart';
import '../ui/features/course/course_screen_controller.dart';
import '../widgets/course_load_state.dart';

class CourseScreen extends StatefulWidget {
  final String id;
  final CourseLoader? courseLoader;
  final CourseScreenController? controller;
  const CourseScreen({
    super.key,
    required this.id,
    this.courseLoader,
    this.controller,
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  late final CourseScreenController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        CourseScreenController(
          loader: widget.courseLoader ?? CourseStorage.instance.loadAll,
        );
    _controller.load(widget.id);
  }

  @override
  void didUpdateWidget(covariant CourseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _controller.load(widget.id);
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final s = S.of(context);
        final course = _controller.course;
        return Scaffold(
          backgroundColor: ExamColors.canvas,
          appBar: AppBar(
            backgroundColor: ExamColors.canvas,
            foregroundColor: ExamColors.ink,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course?.title ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  s.pruefungsteile,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          body: _controller.status == CourseScreenStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : _controller.status == CourseScreenStatus.error
              ? CourseLoadFailureView(
                  failure: CourseLoadFailure.error,
                  onRetry: () => _controller.load(widget.id),
                )
              : _controller.status == CourseScreenStatus.notFound
              ? CourseLoadFailureView(
                  failure: CourseLoadFailure.notFound,
                  onRetry: () => _controller.load(widget.id),
                )
              : _sections(context, course!, s),
          bottomNavigationBar:
              course != null && course.sections.values.every((v) => v.isEmpty)
              ? Container(
                  color: const Color(0xFFFFEBEE),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    s.abschnitteNichtErkannt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 13,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _sections(BuildContext context, ParsedCourse course, S s) {
    final available = sectionMeta.entries
        .where((e) => (course.sections[e.key] ?? []).isNotEmpty)
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          if (available.isNotEmpty) ...[
            _ProbeCard(
              onTap: () => context.push('/course/${course.id}/probe-pruefung'),
              label: s.pruefungssimulation,
            ),
            const SizedBox(height: 14),
          ],
          for (final entry in available) ...[
            _TeilCard(
              eyebrow: entry.value.label,
              title: entry.value.taskName,
              description: s.variantenCount(course.sections[entry.key]!.length),
              icon: entry.value.icon,
              color: entry.value.color,
              onTap: () => context.push('/course/${course.id}/${entry.key}'),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ProbeCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ProbeCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ExamColors.teal, Color(0xFF27B6B9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ExamColors.teal.withValues(alpha: 0.24),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
            ],
          ),
        ),
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
          color: ExamColors.surface,
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
                        color: ExamColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
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
