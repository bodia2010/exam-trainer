import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/strings.dart';
import '../models/parsed_course.dart' show sectionMeta;
import '../services/course_storage.dart';
import '../ui/core/theme/exam_theme.dart';
import '../widgets/course_load_state.dart';

class SectionListScreen extends StatefulWidget {
  final String courseId;
  final String sectionType;
  final CourseLoader? courseLoader;
  const SectionListScreen({
    super.key,
    required this.courseId,
    required this.sectionType,
    this.courseLoader,
  });

  @override
  State<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends State<SectionListScreen> {
  List<dynamic> _variants = [];
  bool _loading = true;
  CourseLoadFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final all =
          await (widget.courseLoader ?? CourseStorage.instance.loadAll)();
      final course = all.where((c) => c.id == widget.courseId).firstOrNull;
      final variants = course?.sections[widget.sectionType] ?? [];
      // Force the same cast itemBuilder performs per row to run now, inside
      // this try block, so one malformed variant lands on the existing
      // error state instead of crashing the whole list mid-scroll.
      for (final variant in variants) {
        variant as Map<String, dynamic>;
      }
      if (mounted) {
        setState(() {
          _variants = variants;
          _loading = false;
          _failure = course == null ? CourseLoadFailure.notFound : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _variants = [];
          _loading = false;
          _failure = CourseLoadFailure.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final meta = sectionMeta[widget.sectionType];
    final accent = meta?.color ?? const Color(0xFF00838F);
    final label = meta?.label ?? widget.sectionType;
    final taskName = meta?.taskName ?? '';

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
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (taskName.isNotEmpty)
              Text(
                taskName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _failure != null
          ? CourseLoadFailureView(
              failure: _failure!,
              onRetry: _load,
              accent: accent,
            )
          : _variants.isEmpty
          ? Center(child: Text(s.keineVarianten))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.varianteWaehlen,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _variants.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final v = _variants[i] as Map<String, dynamic>;
                          final num = v['variant_number'] ?? (i + 1);
                          final topic = (v['topic'] as String?) ?? '';
                          final version = (v['version'] as String?) ?? '';
                          return _VariantCard(
                            number: '$num',
                            title: version.isEmpty
                                ? s.variante(num)
                                : s.varianteMitVersion(num, version),
                            subtitle: topic,
                            accent: accent,
                            onTap: () => context.push(
                              '/course/${widget.courseId}/${widget.sectionType}/$i',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _VariantCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ExamColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: accent, width: 5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ExamColors.ink,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
