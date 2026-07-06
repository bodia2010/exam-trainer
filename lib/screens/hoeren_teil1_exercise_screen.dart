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
  static const _accent = Color(0xFF00838F);

  Map<String, dynamic>? _variant;
  final Map<int, bool?> _rfAnswers = {};
  final Map<int, String?> _mcAnswers = {};
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

  List<Map<String, dynamic>> get _pairs =>
      ((_variant?['question_pairs'] as List?) ?? []).cast<Map<String, dynamic>>();

  int get _totalQuestions => _pairs.fold(0, (sum, pair) {
        var n = 0;
        if (pair['richtig_falsch'] != null) n++;
        if (pair['multiple_choice'] != null) n++;
        return sum + n;
      });

  bool get _allAnswered {
    for (final pair in _pairs) {
      final rf = pair['richtig_falsch'] as Map<String, dynamic>?;
      final mc = pair['multiple_choice'] as Map<String, dynamic>?;
      if (rf != null && !_rfAnswers.containsKey(rf['number'] as int)) return false;
      if (mc != null && !_mcAnswers.containsKey(mc['number'] as int)) return false;
    }
    return true;
  }

  int get _correctCount {
    var correct = 0;
    for (final pair in _pairs) {
      final rf = pair['richtig_falsch'] as Map<String, dynamic>?;
      final mc = pair['multiple_choice'] as Map<String, dynamic>?;
      if (rf != null && _rfAnswers[rf['number'] as int] == rf['answer']) correct++;
      if (mc != null && _mcAnswers[mc['number'] as int] == mc['correct_letter']) correct++;
    }
    return correct;
  }

  void _check() {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte alle Aufgaben beantworten.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _showAnswers = true);
  }

  void _reset() {
    setState(() {
      _rfAnswers.clear();
      _mcAnswers.clear();
      _showAnswers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = _variant;
    if (v == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final varNum = v['variant_number'] ?? (widget.index + 1);
    final version = (v['version'] as String?) ?? '';
    final audioUrl = v['audio_url'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text(version.isEmpty
            ? 'Hören Teil 1 · Вариант $varNum'
            : 'Hören Teil 1 · Вариант $varNum · $version'),
        elevation: 0,
        actions: [
          if (_showAnswers)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('$_correctCount / $_totalQuestions',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (audioUrl != null) _audioButton(audioUrl),
                const SizedBox(height: 16),
                ..._pairs.map((pair) => _buildPair(pair)),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: _showAnswers
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _correctCount == _totalQuestions
                        ? const Color(0xFF2E7D32)
                        : _correctCount > 0
                            ? const Color(0xFFE65100)
                            : const Color(0xFFC62828),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$_correctCount / $_totalQuestions richtig',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Neu versuchen',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _check,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Prüfen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
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
        onTap: _showAnswers ? null : () => setState(() => _rfAnswers[num] = value),
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
                onTap: _showAnswers
                    ? null
                    : () => setState(() => _mcAnswers[num] = letter),
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
