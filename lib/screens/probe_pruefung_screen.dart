import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/strings.dart';
import '../services/course_storage.dart';
import '../services/probe_exam_service.dart';
import '../ui/features/course/probe_pruefung_controller.dart';
import '../widgets/course_load_state.dart';

// ─── Screen ─────────────────────────────────────────────────────────────────

class ProbePruefungScreen extends StatefulWidget {
  final String courseId;
  final CourseLoader? courseLoader;
  final ProbePruefungController? controller;
  const ProbePruefungScreen({
    super.key,
    required this.courseId,
    this.courseLoader,
    this.controller,
  });

  @override
  State<ProbePruefungScreen> createState() => _ProbePruefungScreenState();
}

class _ProbePruefungScreenState extends State<ProbePruefungScreen> {
  late final ProbePruefungController _controller;
  late final bool _ownsController;
  bool _started = false;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        ProbePruefungController(
          loader: widget.courseLoader ?? CourseStorage.instance.loadAll,
        );
    _controller.load(widget.courseId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      _router = router;
      router?.routerDelegate.addListener(_onRouteChange);
    });
  }

  @override
  void didUpdateWidget(covariant ProbePruefungScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId) {
      _started = false;
      ProbeExamService.instance.stop();
      _controller.load(widget.courseId);
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChange);
    ProbeExamService.instance.stop();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onRouteChange() {
    if (!mounted) return;
    try {
      final uri = _router?.routerDelegate.currentConfiguration.uri;
      if (uri?.path == '/course/${widget.courseId}/probe-pruefung' &&
          ProbeExamService.instance.isActive) {
        final idx = ProbeExamService.instance.currentIdx;
        if (idx >= 0) ProbeExamService.instance.markVisited(idx);
        ProbeExamService.instance.clearCurrent();
        setState(() {});
      }
    } catch (_) {}
  }

  void _regenerate() {
    if (!_controller.regenerate()) return;
    setState(() {
      _started = false;
    });
    ProbeExamService.instance.stop();
  }

  void _start() {
    final items = _controller.parts
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
    context.push(_controller.parts[idx].route);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _controller.course?.title ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: s.neueAufgabenWaehlen,
              onPressed: _controller.status == ProbePruefungStatus.content
                  ? _regenerate
                  : null,
            ),
          ],
        ),
        body: _controller.status == ProbePruefungStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : _controller.status == ProbePruefungStatus.error ||
                  _controller.status == ProbePruefungStatus.notFound
            ? CourseLoadFailureView(
                failure: _controller.status == ProbePruefungStatus.notFound
                    ? CourseLoadFailure.notFound
                    : CourseLoadFailure.error,
                onRetry: () => _controller.load(widget.courseId),
                accent: const Color(0xFF1A237E),
              )
            : ListenableBuilder(
                listenable: ProbeExamService.instance,
                builder: (context, _) => _buildBody(s),
              ),
      ),
    );
  }

  Widget _buildBody(S s) {
    final visited = ProbeExamService.instance.visited;
    final done = visited.length;
    final total = _controller.parts.length;
    final finished = _started && done >= total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (finished)
          _FinishedCard(done: done, total: total)
        else if (!_started)
          _StartCard(
            totalParts: total,
            totalMinutes: _controller.totalMinutes,
            onStart: _start,
          )
        else
          _ProgressHeader(done: done, total: total),
        const SizedBox(height: 16),
        ..._controller.parts.asMap().entries.map((entry) {
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
  final ProbeExamPart part;
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
