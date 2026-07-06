import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/course_storage.dart';
import '../widgets/dialogue_audio_player.dart';

class HoerenTeil1ExerciseScreen extends StatefulWidget {
  final String courseId;
  final int index;
  const HoerenTeil1ExerciseScreen({
    super.key,
    required this.courseId,
    required this.index,
  });

  @override
  State<HoerenTeil1ExerciseScreen> createState() => _HoerenTeil1ExerciseScreenState();
}

class _HoerenTeil1ExerciseScreenState extends State<HoerenTeil1ExerciseScreen> {
  Map<String, dynamic>? _variant;
  Map<int, bool?> _rfAnswers = {};
  Map<int, String?> _mcAnswers = {};
  bool _showAnswers = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await CourseStorage.instance.loadAll();
    final course = all.where((c) => c.id == widget.courseId).firstOrNull;
    if (course != null && mounted) {
      final variants = course.sections['hoeren_teil1'] ?? [];
      if (widget.index < variants.length) {
        setState(() => _variant = variants[widget.index] as Map<String, dynamic>);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _variant;
    if (v == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final pairs = (v['question_pairs'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final varNum = v['variant_number'] ?? (widget.index + 1);
    final version = (v['version'] as String?) ?? '';
    final audioUrl = v['audio_url'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        title: Text(version.isEmpty
            ? 'Hören Teil 1 · Вариант $varNum'
            : 'Hören Teil 1 · Вариант $varNum · $version'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => _showAnswers = !_showAnswers),
            child: Text(
              _showAnswers ? 'Скрыть' : 'Ответы',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (audioUrl != null) _audioButton(audioUrl),
          const SizedBox(height: 16),
          ...pairs.map((pair) => _buildPair(pair)),
        ],
      ),
    );
  }

  Widget _audioButton(String url) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.play_circle_outline),
      label: const Text('Слушать запись'),
    );
  }

  Widget _buildPair(Map<String, dynamic> pair) {
    final rf = pair['richtig_falsch'] as Map<String, dynamic>?;
    final mc = pair['multiple_choice'] as Map<String, dynamic>?;
    final dialogue = pair['dialogue'] as String? ?? '';
    final pairUrl = pair['pair_audio_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pairUrl != null) _audioButton(pairUrl),
        if (dialogue.isNotEmpty) ...[
          DialogueAudioPlayer(
              text: dialogue, accent: const Color(0xFF00838F)),
          const SizedBox(height: 8),
        ],
        if (rf != null) _buildRichtigFalsch(rf),
        if (mc != null) _buildMultipleChoice(mc),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildRichtigFalsch(Map<String, dynamic> rf) {
    final num = rf['number'] as int;
    final statement = rf['statement'] as String? ?? '';
    final correct = rf['answer'] as bool?;
    final selected = _rfAnswers[num];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$num. $statement',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: [
                _rfButton(num, true, 'Richtig', correct, selected),
                const SizedBox(width: 8),
                _rfButton(num, false, 'Falsch', correct, selected),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rfButton(int num, bool value, String label, bool? correct, bool? selected) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.black87;
    if (selected == value) {
      if (_showAnswers) {
        bg = value == correct ? Colors.green : Colors.red;
        fg = Colors.white;
      } else {
        bg = const Color(0xFF00838F);
        fg = Colors.white;
      }
    } else if (_showAnswers && value == correct) {
      bg = Colors.green.shade100;
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rfAnswers[num] = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildMultipleChoice(Map<String, dynamic> mc) {
    final num = mc['number'] as int;
    final stem = mc['stem'] as String? ?? '';
    final options = (mc['options'] as List? ?? []).cast<Map<String, dynamic>>();
    final correct = mc['correct_letter'] as String?;
    final selected = _mcAnswers[num];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$num. $stem', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ...options.map((opt) {
              final letter = opt['letter'] as String;
              final text = opt['text'] as String? ?? '';
              final isSelected = selected == letter;
              final isCorrect = letter == correct;
              Color bg = Colors.grey.shade100;
              if (isSelected) {
                if (_showAnswers) {
                  bg = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
                } else {
                  bg = const Color(0xFFE0F7FA);
                }
              } else if (_showAnswers && isCorrect) {
                bg = Colors.green.shade50;
              }
              return GestureDetector(
                onTap: () => setState(() => _mcAnswers[num] = letter),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text('$letter) $text'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
