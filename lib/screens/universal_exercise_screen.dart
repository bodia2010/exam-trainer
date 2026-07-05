import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/parsed_course.dart' show sectionLabels;
import '../services/course_storage.dart';

/// Renders any section parsed with the universal schema:
/// texts (passages/transcripts), option_pool (for match questions) and
/// typed questions — true_false, choice, match.
class UniversalExerciseScreen extends StatefulWidget {
  final String courseId;
  final String sectionType;
  final int index;
  const UniversalExerciseScreen({
    super.key,
    required this.courseId,
    required this.sectionType,
    required this.index,
  });

  @override
  State<UniversalExerciseScreen> createState() =>
      _UniversalExerciseScreenState();
}

class _UniversalExerciseScreenState extends State<UniversalExerciseScreen> {
  static const _accent = Color(0xFF00838F);

  Map<String, dynamic>? _variant;
  final Map<int, String> _selected = {}; // question number → answer string
  bool _showResults = false;

  List<Map<String, dynamic>> get _questions =>
      ((_variant?['questions'] as List?) ?? []).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _optionPool =>
      ((_variant?['option_pool'] as List?) ?? []).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _texts =>
      ((_variant?['texts'] as List?) ?? []).cast<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await CourseStorage.instance.loadAll();
      final course = all.where((c) => c.id == widget.courseId).firstOrNull;
      if (course != null && mounted) {
        final variants = course.sections[widget.sectionType] ?? [];
        if (widget.index < variants.length) {
          setState(() =>
              _variant = variants[widget.index] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
  }

  int _qNumber(Map<String, dynamic> q) => (q['number'] as num?)?.toInt() ?? 0;

  // The source PDF sometimes writes answer letters in Cyrillic lookalikes
  // ("с (100%)" with Cyrillic с) — map them to Latin before comparing.
  static const _cyrillicLookalikes = {
    'а': 'a', 'в': 'b', 'с': 'c', 'е': 'e', 'о': 'o',
    'р': 'p', 'х': 'x', 'к': 'k', 'м': 'm', 'т': 't',
  };

  String _normalized(Object? answer) {
    final s = answer.toString().trim().toLowerCase();
    return s.split('').map((ch) => _cyrillicLookalikes[ch] ?? ch).join();
  }

  bool get _allAnswered =>
      _questions.isNotEmpty &&
      _questions.every((q) => _selected.containsKey(_qNumber(q)));

  int get _correctCount => _questions
      .where((q) =>
          _selected[_qNumber(q)] != null &&
          _normalized(_selected[_qNumber(q)]) == _normalized(q['answer']))
      .length;

  Color get _scoreColor {
    final total = _questions.length;
    if (total == 0) return Colors.grey;
    final c = _correctCount;
    if (c >= total) return const Color(0xFF2E7D32);
    if (c >= total * 0.7) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  bool get _isHoeren => widget.sectionType.startsWith('hoeren');

  @override
  Widget build(BuildContext context) {
    final v = _variant;
    if (v == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final varNum = v['variant_number'] ?? (widget.index + 1);
    final topic = (v['topic'] as String?) ?? '';
    final audioUrl = v['audio_url'] as String?;
    final label = sectionLabels[widget.sectionType] ?? widget.sectionType;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label · Вариант $varNum',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            if (topic.isNotEmpty)
              Text(topic,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (audioUrl != null && audioUrl.isNotEmpty) ...[
            _audioButton(audioUrl),
            const SizedBox(height: 12),
          ],
          ..._texts.map(_textTile),
          if (_texts.isNotEmpty) const SizedBox(height: 12),
          if (_optionPool.isNotEmpty) ...[
            _poolCard(),
            const SizedBox(height: 12),
          ],
          ..._questions.map(_questionCard),
          const SizedBox(height: 8),
          _actionBar(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _audioButton(String url) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.play_circle_outline),
      label: const Text('Слушать запись'),
    );
  }

  Widget _textTile(Map<String, dynamic> t) {
    final title = (t['title'] as String?) ?? 'Текст';
    final content = (t['content'] as String?) ?? '';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        // Reading passages open by default; Hören transcripts are spoilers
        initiallyExpanded: !_isHoeren,
        shape: const Border(),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: _accent, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(content, style: const TextStyle(height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _poolCard() {
    final used = _selected.values.map(_normalized).toSet();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ВАРИАНТЫ ОТВЕТОВ',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ..._optionPool.map((opt) {
              final letter = (opt['letter'] as String?) ?? '';
              final text = (opt['text'] as String?) ?? '';
              final isUsed = used.contains(_normalized(letter));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '$letter)  $text',
                  style: TextStyle(
                    fontSize: 14,
                    decoration: isUsed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: isUsed ? Colors.grey[400] : Colors.black87,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(Map<String, dynamic> q) {
    final type = (q['type'] as String?) ?? 'choice';
    return switch (type) {
      'true_false' => _trueFalseCard(q),
      'match' => _matchCard(q),
      _ => _choiceCard(q),
    };
  }

  // ─── true / false ────────────────────────────────────────────────────────

  Widget _trueFalseCard(Map<String, dynamic> q) {
    final num = _qNumber(q);
    final text = (q['text'] as String?) ?? '';
    final selected = _selected[num];

    return _qCard(
      children: [
        Text('$num. $text',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          children: [
            _tfButton(q, 'richtig', 'Richtig', selected),
            const SizedBox(width: 8),
            _tfButton(q, 'falsch', 'Falsch', selected),
          ],
        ),
      ],
    );
  }

  Widget _tfButton(
      Map<String, dynamic> q, String value, String label, String? selected) {
    final num = _qNumber(q);
    final correct = _normalized(q['answer']);
    Color bg = Colors.grey.shade200;
    Color fg = Colors.black87;
    if (selected == value) {
      if (_showResults) {
        bg = value == correct ? Colors.green : Colors.red;
        fg = Colors.white;
      } else {
        bg = _accent;
        fg = Colors.white;
      }
    } else if (_showResults && value == correct) {
      bg = Colors.green.shade100;
    }
    return Expanded(
      child: GestureDetector(
        onTap: _showResults
            ? null
            : () => setState(() => _selected[num] = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ─── multiple choice ─────────────────────────────────────────────────────

  Widget _choiceCard(Map<String, dynamic> q) {
    final num = _qNumber(q);
    final text = (q['text'] as String?) ?? '';
    final options =
        ((q['options'] as List?) ?? []).cast<Map<String, dynamic>>();
    final correct = _normalized(q['answer']);
    final selected = _selected[num];

    return _qCard(
      children: [
        Text('$num. $text',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        ...options.map((opt) {
          final letter = (opt['letter'] as String?) ?? '';
          final optText = (opt['text'] as String?) ?? '';
          final isSelected = selected == letter;
          final isCorrect = _normalized(letter) == correct;
          Color bg = Colors.grey.shade100;
          if (isSelected) {
            if (_showResults) {
              bg = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
            } else {
              bg = const Color(0xFFE0F7FA);
            }
          } else if (_showResults && isCorrect) {
            bg = Colors.green.shade50;
          }
          return GestureDetector(
            onTap: _showResults
                ? null
                : () => setState(() => _selected[num] = letter),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text('$letter) $optText'),
            ),
          );
        }),
      ],
    );
  }

  // ─── match (answer from option_pool) ─────────────────────────────────────

  Widget _matchCard(Map<String, dynamic> q) {
    final num = _qNumber(q);
    final text = (q['text'] as String?) ?? '';
    final correct = _normalized(q['answer']);
    final selected = _selected[num];

    // Statements start with the person's name — set it in bold.
    final spaceIdx = text.indexOf(' ');
    final head = spaceIdx > 0 ? text.substring(0, spaceIdx) : text;
    final tail = spaceIdx > 0 ? text.substring(spaceIdx) : '';

    return _qCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFFE0F7FA),
              child: Text('$num',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _accent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      color: Colors.black87, fontSize: 14, height: 1.4),
                  children: [
                    TextSpan(
                        text: head,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: tail),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: _optionPool.map((opt) {
            final letter = (opt['letter'] as String?) ?? '';
            final isSelected =
                selected != null && _normalized(selected) == _normalized(letter);
            final isCorrect = _normalized(letter) == correct;

            Color bg = Colors.white;
            Color fg = Colors.black87;
            Color borderColor = Colors.grey.shade300;
            if (isSelected) {
              if (_showResults) {
                bg = isCorrect ? Colors.green : Colors.red;
                fg = Colors.white;
                borderColor = bg;
              } else {
                bg = _accent;
                fg = Colors.white;
                borderColor = _accent;
              }
            } else if (_showResults && isCorrect) {
              bg = Colors.green.shade50;
              fg = Colors.green.shade800;
              borderColor = Colors.green;
            }

            return GestureDetector(
              onTap: _showResults
                  ? null
                  : () => setState(() => _selected[num] = letter),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(letter,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _qCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // ─── action bar ──────────────────────────────────────────────────────────

  Widget _actionBar() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    if (!_showResults) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _allAnswered ? () => setState(() => _showResults = true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Prüfen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return Row(
      children: [
        Chip(
          label: Text(
            '$_correctCount von ${_questions.length} richtig',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: _scoreColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() {
              _selected.clear();
              _showResults = false;
            }),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: const BorderSide(color: _accent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Neu versuchen',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
