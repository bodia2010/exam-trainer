import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/b2_beruf_sprechen_data.dart';
import '../data/b2_beruf_smalltalk_data.dart';
import '../data/b2_beruf_teil3_data.dart';
import '../l10n/strings.dart';
import '../models/parsed_course.dart';
import '../services/course_storage.dart';
import '../services/probe_exam_service.dart';

// ─── Data model ─────────────────────────────────────────────────────────────

/// One step of the walk-through: either one randomly-picked variant from
/// this course's own sections, or (for Sprechen, which every course gets
/// — it's fixed content bundled with the app, not something a PDF import
/// produces) a randomly-picked topic from the built-in bank.
class _Part {
  final String label; // e.g. "Hören Teil 1"
  final String subtitle; // e.g. "Variante 3" or a Sprechen topic
  final String route;
  final Color color;
  final IconData icon;
  final int minutes;

  const _Part({
    required this.label,
    required this.subtitle,
    required this.route,
    required this.color,
    required this.icon,
    required this.minutes,
  });
}

// Approximate per-part timings for the real telc B2 Beruf format (minutes),
// split out of the same official per-group totals used across the app
// (Hören ~20, Lesen ~45, Sprachbausteine ~35, Sprechen ~16).
const _minutesByType = <String, int>{
  'hoeren_teil1': 5,
  'hoeren_teil2': 5,
  'hoeren_teil3': 5,
  'hoeren_teil4': 5,
  'lesen_teil1': 11,
  'lesen_teil2': 12,
  'lesen_teil3': 11,
  'lesen_teil4': 11,
  'beschwerde': 20,
  'telefonnotiz': 5,
  'sprachbausteine_teil1': 17,
  'sprachbausteine_teil2': 18,
};

List<_Part> _buildPlan(ParsedCourse course, Random rng) {
  final parts = <_Part>[];

  for (final entry in sectionMeta.entries) {
    final type = entry.key;
    final variants = course.sections[type] ?? const [];
    if (variants.isEmpty) continue;
    final index = rng.nextInt(variants.length);
    final v = variants[index] as Map<String, dynamic>;
    final varNum = v['variant_number'] ?? (index + 1);
    parts.add(
      _Part(
        label: entry.value.label,
        subtitle: 'Variante $varNum',
        route: '/course/${course.id}/$type/$index',
        color: entry.value.color,
        icon: entry.value.icon,
        minutes: _minutesByType[type] ?? 10,
      ),
    );
  }

  // Sprechen is fixed content bundled with the app — always available,
  // regardless of what the imported PDF contained.
  const sprechenColor = Color(0xFF6A1B9A);
  final sp1 =
      b2BerufSprechenExercises[rng.nextInt(b2BerufSprechenExercises.length)];
  final sp2 =
      b2BerufSmalltalkExercises[rng.nextInt(b2BerufSmalltalkExercises.length)];
  final sp3 = b2BerufTeil3Exercises[rng.nextInt(b2BerufTeil3Exercises.length)];
  parts.addAll([
    _Part(
      label: 'Sprechen Teil 1',
      subtitle: sp1.topic,
      route: '/sprechen/b2-beruf/teil1/${sp1.id}',
      color: sprechenColor,
      icon: Icons.record_voice_over_rounded,
      minutes: 3,
    ),
    _Part(
      label: 'Sprechen Teil 2',
      subtitle: 'Thema ${sp2.number}',
      route: '/sprechen/b2-beruf/teil2/${sp2.id}',
      color: sprechenColor,
      icon: Icons.forum_rounded,
      minutes: 3,
    ),
    _Part(
      label: 'Sprechen Teil 3',
      subtitle: 'Situation ${sp3.number}',
      route: '/sprechen/b2-beruf/teil3/${sp3.id}',
      color: sprechenColor,
      icon: Icons.groups_rounded,
      minutes: 10,
    ),
  ]);

  return parts;
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class ProbePruefungScreen extends StatefulWidget {
  final String courseId;
  const ProbePruefungScreen({super.key, required this.courseId});

  @override
  State<ProbePruefungScreen> createState() => _ProbePruefungScreenState();
}

class _ProbePruefungScreenState extends State<ProbePruefungScreen> {
  ParsedCourse? _course;
  bool _loading = true;
  List<_Part> _parts = [];
  late Random _rng;
  bool _started = false;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _rng = Random();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router = GoRouter.of(context);
      _router.routerDelegate.addListener(_onRouteChange);
    });
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChange);
    ProbeExamService.instance.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await CourseStorage.instance.loadAll();
    final course = all.where((c) => c.id == widget.courseId).firstOrNull;
    if (!mounted) return;
    // _buildPlan casts each variant to Map<String, dynamic> — computed
    // before setState (not inside it) so a schema-drift crash there is
    // caught here and degrades to the existing "course not found" state
    // instead of crashing the widget tree.
    var parts = const <_Part>[];
    var planFailed = false;
    if (course != null) {
      try {
        parts = _buildPlan(course, _rng);
      } catch (_) {
        planFailed = true;
      }
    }
    setState(() {
      _course = planFailed ? null : course;
      _parts = parts;
      _loading = false;
    });
  }

  void _onRouteChange() {
    try {
      final uri = _router.routerDelegate.currentConfiguration.uri;
      if (uri.path == '/course/${widget.courseId}/probe-pruefung' &&
          ProbeExamService.instance.isActive) {
        final idx = ProbeExamService.instance.currentIdx;
        if (idx >= 0) ProbeExamService.instance.markVisited(idx);
        ProbeExamService.instance.clearCurrent();
        setState(() {});
      }
    } catch (_) {}
  }

  void _regenerate() {
    final course = _course;
    if (course == null) return;
    final rng = Random();
    final List<_Part> parts;
    try {
      parts = _buildPlan(course, rng);
    } catch (_) {
      // A newly-rolled combination hit a malformed variant — keep showing
      // the previous (already validated) plan rather than crashing.
      return;
    }
    setState(() {
      _rng = rng;
      _parts = parts;
      _started = false;
    });
    ProbeExamService.instance.stop();
  }

  void _start() {
    final items = _parts
        .map(
          (p) => ProbeItem(
            sectionName: p.label,
            partLabel: '',
            exerciseName: p.subtitle,
            route: p.route,
          ),
        )
        .toList();
    ProbeExamService.instance.start(items);
    setState(() => _started = true);
  }

  void _open(int idx) {
    ProbeExamService.instance.goTo(idx);
    context.push(_parts[idx].route);
  }

  int get _totalMinutes => _parts.fold(0, (sum, p) => sum + p.minutes);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.pruefungssimulation,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _course?.title ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: s.neueAufgabenWaehlen,
            onPressed: _regenerate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _course == null
          ? Center(child: Text(s.kursNichtGefunden))
          : ListenableBuilder(
              listenable: ProbeExamService.instance,
              builder: (context, _) => _buildBody(s),
            ),
    );
  }

  Widget _buildBody(S s) {
    final visited = ProbeExamService.instance.visited;
    final done = visited.length;
    final total = _parts.length;
    final finished = _started && done >= total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (finished)
          _FinishedCard(done: done, total: total)
        else if (!_started)
          _StartCard(
            totalParts: total,
            totalMinutes: _totalMinutes,
            onStart: _start,
          )
        else
          _ProgressHeader(done: done, total: total),
        const SizedBox(height: 16),
        ..._parts.asMap().entries.map((entry) {
          final i = entry.key;
          final part = entry.value;
          return _PartCard(
            part: part,
            index: i,
            done: visited.contains(i),
            enabled: _started,
            onTap: () => _open(i),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Start card ───────────────────────────────────────────────────────────

class _StartCard extends StatelessWidget {
  final int totalParts;
  final int totalMinutes;
  final VoidCallback onStart;

  const _StartCard({
    required this.totalParts,
    required this.totalMinutes,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.pruefungssimulation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      s.aufgabenMinuten(totalParts, totalMinutes),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                s.pruefungStarten,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress header ────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressHeader({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? done / total : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF1A237E)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$done / $total',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Part card ──────────────────────────────────────────────────────────────

class _PartCard extends StatelessWidget {
  final _Part part;
  final int index;
  final bool done;
  final bool enabled;
  final VoidCallback onTap;

  const _PartCard({
    required this.part,
    required this.index,
    required this.done,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: done ? Colors.grey.shade300 : part.color,
                width: 5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: done
                      ? Colors.grey.shade100
                      : part.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  done ? Icons.check_circle_rounded : part.icon,
                  color: done ? Colors.grey.shade400 : part.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: done
                            ? Colors.grey.shade500
                            : const Color(0xFF1A237E),
                      ),
                    ),
                    Text(
                      part.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: done
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: done
                      ? Colors.grey.shade100
                      : part.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${part.minutes} min',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: done ? Colors.grey.shade400 : part.color,
                  ),
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: done ? Colors.grey.shade300 : part.color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Finished card ──────────────────────────────────────────────────────────

class _FinishedCard extends StatelessWidget {
  final int done;
  final int total;

  const _FinishedCard({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pct = total > 0 ? (done / total * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 52),
          const SizedBox(height: 12),
          Text(
            s.probepruefungAbgeschlossen,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.aufgabenErledigt(done, total, pct),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
