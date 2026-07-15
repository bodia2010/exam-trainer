import 'package:flutter/material.dart';

import '../../core/theme/exam_theme.dart';

class StartupCoordinator extends ChangeNotifier {
  StartupCoordinator._();

  static final instance = StartupCoordinator._();

  var _ready = false;
  bool get ready => _ready;

  void markReady() {
    if (_ready) return;
    _ready = true;
    notifyListeners();
  }

  void reset() {
    if (!_ready) return;
    _ready = false;
    notifyListeners();
  }
}

/// Keeps one branded layer above router construction and initial page loading.
/// The prepared page is painted behind it first; only then does the target
/// screen call [StartupCoordinator.markReady], so no blank transition frame is
/// ever exposed.
class StartupOverlay extends StatelessWidget {
  const StartupOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StartupCoordinator.instance,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (!StartupCoordinator.instance.ready)
            const StartupScreen(key: ValueKey('app_startup_overlay')),
        ],
      ),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, this.error = false, this.onRetry});

  final bool error;
  final VoidCallback? onRetry;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween(
      begin: 0.96,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExamColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(ExamSpacing.xl),
            child: widget.error
                ? _ErrorState(onRetry: widget.onRetry)
                : _loader(),
          ),
        ),
      ),
    );
  }

  Widget _loader() {
    return Semantics(
      label: 'Exam Trainer wird gestartet',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 116,
              height: 116,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ExamColors.surface,
                borderRadius: BorderRadius.circular(ExamRadius.large),
                border: Border.all(color: ExamColors.border),
                boxShadow: [
                  BoxShadow(
                    color: ExamColors.teal.withValues(alpha: 0.14),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Image.asset('assets/branding/app_icon.png'),
            ),
          ),
          const SizedBox(height: ExamSpacing.lg),
          const Text(
            'Exam Trainer',
            style: TextStyle(
              color: ExamColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: ExamSpacing.sm),
          const Text(
            'Prüfungstrainer wird vorbereitet …',
            textAlign: TextAlign.center,
            style: TextStyle(color: ExamColors.inkMuted, fontSize: 14),
          ),
          const SizedBox(height: ExamSpacing.lg),
          const SizedBox(
            width: 160,
            child: LinearProgressIndicator(
              minHeight: 5,
              borderRadius: BorderRadius.all(Radius.circular(99)),
              color: ExamColors.teal,
              backgroundColor: ExamColors.progressTrack,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: ExamColors.coralSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_off_rounded,
            color: ExamColors.coral,
            size: 38,
          ),
        ),
        const SizedBox(height: ExamSpacing.lg),
        const Text(
          'Exam Trainer konnte nicht gestartet werden.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ExamColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: ExamSpacing.md),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Erneut versuchen'),
        ),
      ],
    );
  }
}
