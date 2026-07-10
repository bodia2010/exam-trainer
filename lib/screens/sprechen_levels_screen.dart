import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/strings.dart';

/// Level picker for Mündliche Prüfung — the app currently only ships a
/// B2 Beruf topic bank, but this screen exists so adding A1/A2/B1/C1 later
/// is just another card, not a routing rework.
class SprechenLevelsScreen extends StatelessWidget {
  const SprechenLevelsScreen({super.key});

  static const _accent = Color(0xFF6A1B9A);

  static const _levels = [
    (id: 'b2-beruf', label: 'B2 Beruf', teile: 3, themen: 147, available: true),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mündliche Prüfung',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(s.niveauWaehlen,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
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

  static const _accent = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                color: (available ? _accent : Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_outlined,
                  color: available ? _accent : Colors.grey, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: available ? Colors.black87 : Colors.grey)),
                  const SizedBox(height: 4),
                  Text(available ? subtitle : demnaechst,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4)),
                ],
              ),
            ),
            if (available)
              const Icon(Icons.chevron_right, color: Colors.grey)
            else
              const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
