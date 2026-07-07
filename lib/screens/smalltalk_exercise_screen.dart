import 'package:flutter/material.dart';
import '../data/b2_beruf_smalltalk_data.dart';
import '../models/smalltalk_exercise.dart';

class SmalltalkExerciseScreen extends StatefulWidget {
  final String exerciseId;
  const SmalltalkExerciseScreen({super.key, required this.exerciseId});

  @override
  State<SmalltalkExerciseScreen> createState() =>
      _SmalltalkExerciseScreenState();
}

class _SmalltalkExerciseScreenState extends State<SmalltalkExerciseScreen> {
  static const _accentColor = Color(0xFF6A1B9A);

  late final SmalltalkExercise _exercise;

  bool _showDialogue = false;
  bool _showAlternatives = false;

  @override
  void initState() {
    super.initState();
    _exercise =
        b2BerufSmalltalkExercises.firstWhere((e) => e.id == widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thema ${_exercise.number}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Sprechen · Teil 2 · Smalltalk',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStimulusCard(),
            const SizedBox(height: 16),
            if (_exercise.dialogue.isNotEmpty) ...[
              _buildCollapsibleCard(
                label: 'BEISPIELDIALOG',
                expanded: _showDialogue,
                onToggle: () => setState(() => _showDialogue = !_showDialogue),
                child: _buildDialogue(),
              ),
              const SizedBox(height: 16),
            ],
            if (_exercise.alternatives.isNotEmpty) ...[
              _buildCollapsibleCard(
                label: 'ALTERNATIVSÄTZE',
                expanded: _showAlternatives,
                onToggle: () =>
                    setState(() => _showAlternatives = !_showAlternatives),
                child: _buildAlternatives(),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStimulusCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, color: _accentColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AUFGABE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  const Text('Ihr Gesprächspartner sagt:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('A: ',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _accentColor)),
                        Expanded(
                          child: Text(_exercise.stimulus,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.black87)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Reagieren Sie auf die Aussage Ihres Gesprächspartners.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.black54, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogue() {
    return Column(
      children: _exercise.dialogue.map((line) {
        final isA = line.isPersonA;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 2, right: 10),
                decoration: BoxDecoration(
                  color: isA
                      ? _accentColor.withValues(alpha: 0.15)
                      : const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(isA ? 'A' : 'B',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isA ? _accentColor : const Color(0xFF1565C0))),
                ),
              ),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isA
                        ? const Color(0xFFF3E5F5)
                        : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(line.text,
                      style: const TextStyle(
                          fontSize: 14, height: 1.5, color: Colors.black87)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlternatives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _exercise.alternatives.map((alt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alt.label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                      letterSpacing: 0.4)),
              const SizedBox(height: 6),
              ...alt.phrases.map(
                (phrase) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(phrase,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87, height: 1.4)),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCollapsibleCard({
    required String label,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                          letterSpacing: 0.6)),
                  const Spacer(),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      color: _accentColor),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ],
      ),
    );
  }
}
