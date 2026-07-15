import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/strings.dart';

/// Which (provider, course type, level) combination discovery/parsing
/// actually has prompts for — right now only telc B2 Beruf. Picking a
/// profile up front (instead of guessing from the PDF) lets discovery be
/// routed to the right structural description once other profiles ship,
/// rather than forcing every document through the B2-Beruf-shaped schema.
class ExamProfile {
  final String id;
  final String provider;
  final String courseType;
  final String level;
  final bool available;

  const ExamProfile({
    required this.id,
    required this.provider,
    required this.courseType,
    required this.level,
    required this.available,
  });

  String get label => '$provider $courseType $level';
}

const examProfiles = <ExamProfile>[
  ExamProfile(
    id: 'telc-beruf-b2',
    provider: 'telc',
    courseType: 'Beruf',
    level: 'B2',
    available: true,
  ),
  ExamProfile(
    id: 'telc-beruf-b1',
    provider: 'telc',
    courseType: 'Beruf',
    level: 'B1',
    available: false,
  ),
  ExamProfile(
    id: 'telc-allgemein-b2',
    provider: 'telc',
    courseType: 'Allgemein',
    level: 'B2',
    available: false,
  ),
  ExamProfile(
    id: 'telc-allgemein-b1',
    provider: 'telc',
    courseType: 'Allgemein',
    level: 'B1',
    available: false,
  ),
  ExamProfile(
    id: 'telc-pflege-b2',
    provider: 'telc',
    courseType: 'Pflege',
    level: 'B2',
    available: false,
  ),
  ExamProfile(
    id: 'telc-pflege-b1',
    provider: 'telc',
    courseType: 'Pflege',
    level: 'B1',
    available: false,
  ),
  ExamProfile(
    id: 'goethe-allgemein-b2',
    provider: 'Goethe',
    courseType: 'Allgemein',
    level: 'B2',
    available: false,
  ),
  ExamProfile(
    id: 'goethe-allgemein-b1',
    provider: 'Goethe',
    courseType: 'Allgemein',
    level: 'B1',
    available: false,
  ),
  ExamProfile(
    id: 'goethe-allgemein-c1',
    provider: 'Goethe',
    courseType: 'Allgemein',
    level: 'C1',
    available: false,
  ),
];

class ExamProfileScreen extends StatelessWidget {
  const ExamProfileScreen({super.key});

  static const _accent = Color(0xFF00838F);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.pruefungWaehlen,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              s.niveauUndKursWaehlen,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final profile in examProfiles) ...[
            _ProfileCard(
              profile: profile,
              demnaechst: s.demnaechst,
              onTap: profile.available
                  ? () => context.push('/import', extra: profile)
                  : null,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ExamProfile profile;
  final String demnaechst;
  final VoidCallback? onTap;

  const _ProfileCard({
    required this.profile,
    required this.demnaechst,
    required this.onTap,
  });

  static const _accent = Color(0xFF00838F);

  @override
  Widget build(BuildContext context) {
    final available = profile.available;
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (available ? _accent : Colors.grey).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_outlined,
                color: available ? _accent : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: available ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (!available) ...[
                    const SizedBox(height: 3),
                    Text(
                      demnaechst,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ],
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
