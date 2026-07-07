import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hub for Sprechen — B2 Beruf speaking practice. Unlike the other
/// sections, this content is a fixed topic bank (not parsed from a PDF)
/// and lives globally on the home screen, independent of any course.
class SprechenScreen extends StatelessWidget {
  const SprechenScreen({super.key});

  static const _accentColor = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mündliche Prüfung',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('B2 Beruf · Темы для говорения',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Wählen Sie einen Übungstyp:',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            _PartCard(
              title: 'Teil 1',
              subtitle: '8 Themen · Monolog · 2 Minuten sprechen',
              icon: Icons.record_voice_over_outlined,
              onTap: () => context.push('/sprechen/teil1'),
            ),
            const SizedBox(height: 14),
            _PartCard(
              title: 'Teil 2',
              subtitle: '73 Themen · Smalltalk · Dialog und Reaktion',
              icon: Icons.forum_outlined,
              onTap: () => context.push('/sprechen/teil2'),
            ),
            const SizedBox(height: 14),
            _PartCard(
              title: 'Teil 3',
              subtitle: '66 Situationen · Lösungswege diskutieren',
              icon: Icons.psychology_outlined,
              onTap: () => context.push('/sprechen/teil3'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  static const _accentColor = Color(0xFF6A1B9A);

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
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600], height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
