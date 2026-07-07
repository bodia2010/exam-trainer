import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/b2_beruf_teil3_data.dart';

class SprechenTeil3ExerciseScreen extends StatefulWidget {
  final String exerciseId;
  const SprechenTeil3ExerciseScreen({super.key, required this.exerciseId});

  @override
  State<SprechenTeil3ExerciseScreen> createState() =>
      _SprechenTeil3ExerciseScreenState();
}

class _SprechenTeil3ExerciseScreenState
    extends State<SprechenTeil3ExerciseScreen> {
  static const _accentColor = Color(0xFF6A1B9A);

  static const _redemittel = [
    (
      label: 'Problem einleiten',
      phrases: [
        'Hast du schon gehört? Wir haben folgendes Problem: …',
        'Es gibt leider ein Problem mit …',
        'Viele Kunden haben sich darüber beschwert, dass …',
      ]
    ),
    (
      label: 'Nach Ideen fragen',
      phrases: [
        'Wie können wir das Problem lösen? / Was können wir machen?',
        'Hast du eine Idee? / Hast du einen Vorschlag? / Was denkst du?',
      ]
    ),
    (
      label: 'Vorschläge machen',
      phrases: [
        'Zuerst sollten wir … / Wir könnten …',
        'Wichtig ist auch, dass wir …',
        'Ich kümmere mich um … und du kannst …',
      ]
    ),
    (
      label: 'Ursache klären',
      phrases: [
        'Wir müssen klären, wer schuld ist.',
        'Vielleicht hat jemand einen Fehler gemacht.',
        'Vielleicht ist der neue Kollege / die neue Kollegin schuld.',
      ]
    ),
    (
      label: 'Sofortmaßnahmen',
      phrases: [
        'Wir müssen unsere Arbeit genauer kontrollieren.',
        'Wir müssen einen Plan machen.',
        'Wir müssen uns bei den Kunden entschuldigen.',
      ]
    ),
    (
      label: 'Entschuldigung anbieten',
      phrases: [
        'Wir könnten den Kunden einen Rabatt von … % anbieten.',
        'Wir könnten die Kunden telefonisch / per E-Mail kontaktieren.',
        'Wir könnten den Kunden ein kleines Geschenk / einen Gutschein anbieten.',
      ]
    ),
    (
      label: 'Lieferant / Partner',
      phrases: [
        'Wir müssen mit dem Lieferanten / mit der Transportfirma sprechen.',
        'Wir müssen den Lieferanten / die Transportfirma wechseln.',
        'Wir könnten einen anderen Lieferanten / eine andere Transportfirma suchen.',
      ]
    ),
    (
      label: 'Zustimmen / Ablehnen',
      phrases: [
        'Ich stimme dir zu. Das ist eine gute Idee. Das machen wir so!',
        'Ich stimme dir nicht zu. Ich habe einen besseren Vorschlag.',
      ]
    ),
    (
      label: 'Abschluss / Zukunft',
      phrases: [
        'Wir könnten eine Teambesprechung organisieren.',
        'Wie können wir solche Probleme in Zukunft vermeiden?',
        'Wir müssen das Problem so schnell wie möglich lösen.',
        'Außerdem müssen wir …',
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ex = b2BerufTeil3Exercises.firstWhere(
      (e) => e.id == widget.exerciseId,
      orElse: () => b2BerufTeil3Exercises.first,
    );

    final currentIndex =
        b2BerufTeil3Exercises.indexWhere((e) => e.id == widget.exerciseId);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < b2BerufTeil3Exercises.length - 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sprechen · Teil 3',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Situation ${ex.number} von ${b2BerufTeil3Exercises.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        elevation: 0,
        actions: [
          if (hasPrev)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final prev = b2BerufTeil3Exercises[currentIndex - 1];
                context.pushReplacement('/sprechen/b2-beruf/teil3/${prev.id}');
              },
            ),
          if (hasNext)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                final next = b2BerufTeil3Exercises[currentIndex + 1];
                context.pushReplacement('/sprechen/b2-beruf/teil3/${next.id}');
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            icon: Icons.psychology_outlined,
            title: 'Situation ${ex.number}',
            child: Text(ex.description,
                style: const TextStyle(
                    fontSize: 15, height: 1.6, color: Color(0xFF1A237E))),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.checklist_outlined,
            title: 'Diskussionspunkte',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ex.stichpunkte
                  .map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: _accentColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(p,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Color(0xFF37474F))),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (ex.dialogue.isNotEmpty) _DialogueCard(lines: ex.dialogue),
          if (ex.dialogue.isNotEmpty) const SizedBox(height: 12),
          const _RedemittelCard(redemittel: _redemittel),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard(
      {required this.icon, required this.title, required this.child});

  static const _accentColor = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accentColor, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _accentColor)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DialogueCard extends StatefulWidget {
  final List<String> lines;
  const _DialogueCard({required this.lines});

  @override
  State<_DialogueCard> createState() => _DialogueCardState();
}

class _DialogueCardState extends State<_DialogueCard> {
  bool _expanded = false;
  static const _accentColor = Color(0xFF6A1B9A);
  static const _colorA = Color(0xFF6A1B9A);
  static const _colorB = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.question_answer_outlined,
                      color: _accentColor, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Beispieldialog',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _accentColor)),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: _accentColor),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.lines.asMap().entries.map((entry) {
                  final isA = entry.key.isEven;
                  final color = isA ? _colorA : _colorB;
                  final label = isA ? 'A' : 'B';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(top: 1, right: 8),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color)),
                          ),
                        ),
                        Expanded(
                          child: Text(entry.value,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xFF37474F))),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _RedemittelCard extends StatefulWidget {
  final List<({String label, List<String> phrases})> redemittel;

  const _RedemittelCard({required this.redemittel});

  @override
  State<_RedemittelCard> createState() => _RedemittelCardState();
}

class _RedemittelCardState extends State<_RedemittelCard> {
  bool _expanded = false;

  static const _accentColor = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: _accentColor, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Redemittel',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _accentColor)),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: _accentColor),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.redemittel.map((group) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(group.label,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _accentColor)),
                        ),
                        const SizedBox(height: 6),
                        ...group.phrases.map(
                          (p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: _accentColor,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(p,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: Color(0xFF37474F))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
