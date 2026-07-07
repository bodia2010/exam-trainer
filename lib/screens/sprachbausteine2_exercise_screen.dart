import 'package:flutter/material.dart';
import '../services/course_storage.dart';

// ─── Text part model ───────────────────────────────────────────────────────────

enum _PartType { text, gap }

class _Part {
  final _PartType type;
  final String? textContent;
  final int? questionNumber;

  const _Part.text(String t)
      : type = _PartType.text,
        textContent = t,
        questionNumber = null;

  const _Part.gap(int n)
      : type = _PartType.gap,
        textContent = null,
        questionNumber = n;
}

/// Sprachbausteine Teil 2: unlike Teil 1's single shared word pool, each
/// gap here has its own 3 options (a/b/c) — so the picker for gap [52]
/// only ever shows gap 52's own options, not the others'.
class Sprachbausteine2ExerciseScreen extends StatefulWidget {
  final String courseId;
  final int index;
  const Sprachbausteine2ExerciseScreen({
    super.key,
    required this.courseId,
    required this.index,
  });

  @override
  State<Sprachbausteine2ExerciseScreen> createState() =>
      _Sprachbausteine2ExerciseScreenState();
}

class _Sprachbausteine2ExerciseScreenState
    extends State<Sprachbausteine2ExerciseScreen> {
  static const _accent = Color(0xFF5E35B1);

  Map<String, dynamic>? _variant;
  List<_Part> _parts = [];
  Map<int, Map<String, dynamic>> _questionsByNumber = {};
  final Map<int, String> _selections = {}; // questionNumber -> letter
  bool _showResults = false;

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
        final variants = course.sections['sprachbausteine_teil2'] ?? [];
        if (widget.index < variants.length) {
          final v = variants[widget.index] as Map<String, dynamic>;
          _initExercise(v);
          if (mounted) setState(() => _variant = v);
        }
      }
    } catch (_) {}
  }

  void _initExercise(Map<String, dynamic> v) {
    final texts = ((v['texts'] as List?) ?? []).cast<Map<String, dynamic>>();
    final content =
        _dehyphenate(texts.isNotEmpty ? (texts[0]['content'] as String? ?? '') : '');
    final questions =
        ((v['questions'] as List?) ?? []).cast<Map<String, dynamic>>();

    _questionsByNumber = {
      for (final q in questions) (q['number'] as num).toInt(): q,
    };
    _parts = _buildParts(content);
  }

  // The source PDF hard-wraps and hyphenates lines mid-word (e.g.
  // "Ausbildungs-" / "konzept"), and Gemini's extraction sometimes
  // preserves those raw line breaks.
  String _dehyphenate(String text) =>
      text.replaceAllMapped(RegExp(r'(\w)-\n(\w)'), (m) => '${m[1]}${m[2]}');

  List<_Part> _buildParts(String text) {
    final matches = RegExp(r'\[(\d+)\]').allMatches(text).toList();
    final parts = <_Part>[];
    int last = 0;
    for (var mi = 0; mi < matches.length; mi++) {
      final m = matches[mi];
      if (m.start > last) parts.add(_Part.text(text.substring(last, m.start)));
      final qn = int.parse(m.group(1)!);
      parts.add(_Part.gap(qn));
      last = m.end;

      // The source PDF sometimes leaves the correct option's text written
      // out right after its own gap marker (an inline-answer-key
      // artifact) — strip it so the exercise doesn't give the answer away.
      final q = _questionsByNumber[qn];
      final correctLetter = q?['answer'] as String?;
      final options = ((q?['options'] as List?) ?? []).cast<Map<String, dynamic>>();
      final correctWord = correctLetter == null
          ? null
          : options
              .firstWhere((o) => o['letter'] == correctLetter,
                  orElse: () => {})['text'] as String?;
      if (correctWord != null && correctWord.isNotEmpty) {
        final nextStart = mi + 1 < matches.length ? matches[mi + 1].start : text.length;
        final between = text.substring(last, nextStart);
        final leak = RegExp('^\\s*${RegExp.escape(correctWord)}\\b', caseSensitive: false)
            .matchAsPrefix(between);
        if (leak != null) last += leak.end;
      }
    }
    if (last < text.length) parts.add(_Part.text(text.substring(last)));
    return parts;
  }

  bool get _allAnswered =>
      _questionsByNumber.keys.every((n) => _selections.containsKey(n));

  int get _correctCount => _questionsByNumber.keys
      .where((n) => _selections[n] == _questionsByNumber[n]!['answer'])
      .length;

  Color get _scoreColor {
    final total = _questionsByNumber.length;
    final c = _correctCount;
    if (total == 0) return Colors.grey;
    if (c >= total) return const Color(0xFF2E7D32);
    if (c >= total * 0.7) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  List<InlineSpan> _buildSpans() {
    const bodyStyle =
        TextStyle(fontSize: 15, color: Colors.black87, height: 1.6);
    return _parts.map((part) {
      if (part.type == _PartType.text) {
        return TextSpan(text: part.textContent, style: bodyStyle);
      }
      final n = part.questionNumber!;
      final q = _questionsByNumber[n];
      if (q == null) return TextSpan(text: '[$n]', style: bodyStyle);
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _GapWidget(
          question: q,
          selected: _selections[n],
          showResults: _showResults,
          onSelect: (letter) => setState(() => _selections[n] = letter),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final v = _variant;
    if (v == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final varNum = v['variant_number'] ?? (widget.index + 1);
    final topic = (v['topic'] as String?) ?? '';
    final version = (v['version'] as String?) ?? '';
    final total = _questionsByNumber.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                version.isEmpty
                    ? 'Вариант $varNum'
                    : 'Вариант $varNum · $version',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Sprachbausteine Teil 2${topic.isNotEmpty ? ' · $topic' : ''}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              child: RichText(text: TextSpan(children: _buildSpans())),
            ),
            const SizedBox(height: 16),
            if (!_showResults)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _allAnswered
                            ? () => setState(() => _showResults = true)
                            : null,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Prüfen',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showResults = true),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Antworten'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Chip(
                    label: Text(
                      '$_correctCount von $total richtig',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: _scoreColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _selections.clear();
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
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

// ─── Inline gap widget ─────────────────────────────────────────────────────────

class _GapWidget extends StatelessWidget {
  static const _accent = Color(0xFF5E35B1);

  final Map<String, dynamic> question;
  final String? selected;
  final bool showResults;
  final ValueChanged<String> onSelect;

  const _GapWidget({
    required this.question,
    required this.selected,
    required this.showResults,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options =
        ((question['options'] as List?) ?? []).cast<Map<String, dynamic>>();
    final correct = question['answer'] as String?;

    if (showResults) {
      // Nothing was picked — show the correct option instead of leaving a
      // blank, so "Antworten zeigen" actually reveals the answer here too.
      final unanswered = selected == null;
      final displayLetter = selected ?? correct;
      if (displayLetter == null) {
        return const Text('___',
            style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500));
      }
      final isCorrect = !unanswered && selected == correct;
      final selectedText = options
          .firstWhere((o) => o['letter'] == displayLetter,
              orElse: () => {'text': displayLetter})['text']
          .toString();
      final color = unanswered
          ? const Color(0xFF1565C0)
          : isCorrect
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          selectedText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: DropdownButton<String>(
        value: selected,
        hint: const Text('___', style: TextStyle(fontSize: 14, color: _accent)),
        isDense: true,
        underline: Container(height: 1, color: _accent),
        onChanged: (v) {
          if (v != null) onSelect(v);
        },
        items: options.map((opt) {
          final letter = opt['letter'] as String? ?? '';
          final text = opt['text'] as String? ?? '';
          return DropdownMenuItem<String>(
            value: letter,
            child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          );
        }).toList(),
      ),
    );
  }
}
