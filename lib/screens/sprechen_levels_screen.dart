import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/strings.dart';
import '../ui/core/theme/exam_theme.dart';

/// Level picker for Mündliche Prüfung — the app currently only ships a
/// B2 Beruf topic bank, but this screen exists so adding A1/A2/B1/C1 later
/// is just another card, not a routing rework.
class SprechenLevelsScreen extends StatelessWidget {
  const SprechenLevelsScreen({super.key});

  static const _levels = [
    (id: 'b2-beruf', label: 'B2 Beruf', teile: 3, themen: 147, available: true),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ExamColors.canvas,
        foregroundColor: ExamColors.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mündliche Prüfung',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              s.niveauWaehlen,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        elevation: 0,
      ),
      backgroundColor: ExamColors.canvas,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final level in _levels) ...[
            _LevelCard(
              label: level.label,
              subtitle: s.teileThemen(level.teile, level.themen),
              available: level.available,
              demnaechst: s.demnaechst,
              onTap: level.available
                  ? () => context.push('/sprechen/${level.id}')
                  : null,
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool available;
  final String demnaechst;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.label,
    required this.subtitle,
    required this.available,
    required this.demnaechst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ExamColors.surface,
          borderRadius: BorderRadius.circular(ExamRadius.medium),
          border: Border.all(color: ExamColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: available
                    ? ExamColors.coralSoft
                    : ExamColors.progressTrack,
                borderRadius: BorderRadius.circular(ExamRadius.small),
              ),
              child: Icon(
                Icons.school_outlined,
                color: available ? ExamColors.coral : ExamColors.inkMuted,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: available ? ExamColors.ink : ExamColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    available ? subtitle : demnaechst,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ExamColors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (available)
              const Icon(Icons.chevron_right, color: ExamColors.coral)
            else
              const Icon(
                Icons.lock_outline,
                color: ExamColors.inkMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
