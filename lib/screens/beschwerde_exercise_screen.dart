import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/parsed_course.dart' show sectionMeta;
import '../services/course_storage.dart';
import '../widgets/favorite_button.dart';

/// Design and behaviour ported from deutch-lernen's BeschwerdeExerciseScreen:
/// two letters (internal memo + customer complaint), two multiple-choice
/// questions, a writing field with a live word counter and a 15-minute
/// timer that starts on the first keystroke, and the model answer letter
/// always shown at the bottom.
class BeschwerdeExerciseScreen extends StatefulWidget {
  final String courseId;
  final int index;
  const BeschwerdeExerciseScreen({
    super.key,
    required this.courseId,
    required this.index,
  });

  @override
  State<BeschwerdeExerciseScreen> createState() =>
      _BeschwerdeExerciseScreenState();
}

class _BeschwerdeExerciseScreenState extends State<BeschwerdeExerciseScreen> {
  static const _maxWords = 150;
  static const _timerSeconds = 15 * 60;

  Color get _accent =>
      sectionMeta['beschwerde']?.color ?? const Color(0xFFC62828);

  Map<String, dynamic>? _variant;
  final TextEditingController _textController = TextEditingController();

  List<Map<String, dynamic>> _questions = [];
  final Map<int, String> _selected = {}; // question number -> letter
  bool _showResults = false;

  int _wordCount = 0;
  int _secondsLeft = _timerSeconds;
  bool _timerStarted = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await CourseStorage.instance.loadAll();
      final course = all.where((c) => c.id == widget.courseId).firstOrNull;
      if (course != null && mounted) {
        final variants = course.sections['beschwerde'] ?? [];
        if (widget.index < variants.length) {
          final v = variants[widget.index] as Map<String, dynamic>;
          final qs = ((v['questions'] as List?) ?? [])
              .cast<Map<String, dynamic>>();
          qs.sort((a, b) => ((a['number'] as num?) ?? 0)
              .compareTo((b['number'] as num?) ?? 0));
          setState(() {
            _variant = v;
            _questions = qs;
          });
        }
      }
    } catch (_) {}
  }

  // ─── letters (from the universal `texts` field) ───────────────────────────

  List<Map<String, dynamic>> get _texts =>
      ((_variant?['texts'] as List?) ?? []).cast<Map<String, dynamic>>();

  String? _findText(bool Function(String title) match) {
    for (final t in _texts) {
      final title = (t['title'] as String? ?? '').toLowerCase();
      if (match(title)) return (t['content'] as String?) ?? '';
    }
    return null;
  }

  String get _memoText =>
      _findText((t) => t.contains('intern')) ??
      (_texts.isNotEmpty ? (_texts[0]['content'] as String? ?? '') : '');

  String get _complaintText =>
      _findText((t) => t.contains('beschwerde') && !t.contains('antwort')) ??
      (_texts.length > 1 ? (_texts[1]['content'] as String? ?? '') : '');

  String get _modelAnswerText =>
      _findText((t) => t.contains('musterantwort') || t.contains('antwort')) ??
      (_texts.length > 2 ? (_texts[2]['content'] as String? ?? '') : '');

  // ─── word count + timer ────────────────────────────────────────────────────

  void _onTextChanged() {
    final text = _textController.text;
    final words = text.trim().isEmpty
        ? 0
        : text
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => RegExp(r'\p{L}|\p{N}', unicode: true).hasMatch(w))
            .length;
    if (words != _wordCount) setState(() => _wordCount = words);
    if (!_timerStarted && text.isNotEmpty) _startTimer();
  }

  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _timerDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _timerExpired => _timerStarted && _secondsLeft == 0;

  // ─── scoring ────────────────────────────────────────────────────────────

  String _normalized(Object? v) => v.toString().trim().toLowerCase();

  bool get _questionsAnswered =>
      _questions.isNotEmpty &&
      _questions.every((q) => _selected.containsKey(q['number'] as int));

  int get _correctCount => _questions
      .where((q) =>
          _selected[q['number'] as int] != null &&
          _normalized(_selected[q['number'] as int]) ==
              _normalized(q['answer']))
      .length;

  void _submit() {
    _timer?.cancel();
    setState(() => _showResults = true);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _selected.clear();
      _showResults = false;
      _textController.clear();
      _wordCount = 0;
      _secondsLeft = _timerSeconds;
      _timerStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final v = _variant;
    if (v == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final varNum = v['variant_number'] ?? (widget.index + 1);
    final topic = (v['topic'] as String?) ?? '';
    final version = (v['version'] as String?) ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              version.isEmpty
                  ? s.variante(varNum)
                  : s.varianteMitVersion(varNum, version),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(topic,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          FavoriteButton(
            favId: '/course/${widget.courseId}/beschwerde/${widget.index}',
            title: version.isEmpty
                ? s.variante(varNum)
                : s.varianteMitVersion(varNum, version),
            subtitle: 'Beschwerde',
            route: '/course/${widget.courseId}/beschwerde/${widget.index}',
            courseId: widget.courseId,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Letter 1: internal memo ───────────────────────────────
            _LetterCard(
              label: s.internerHinweis,
              labelColor: const Color(0xFF795548),
              backgroundColor: const Color(0xFFFFF8F5),
              borderColor: const Color(0xFFBCAAA4),
              text: _memoText,
            ),
            const SizedBox(height: 12),

            // ─── Letter 2: customer complaint ──────────────────────────
            _LetterCard(
              label: s.kundenbeschwerde,
              labelColor: const Color(0xFF1565C0),
              backgroundColor: Colors.white,
              borderColor: const Color(0xFF90CAF9),
              text: _complaintText,
            ),
            const SizedBox(height: 16),

            // ─── Questions ──────────────────────────────────────────────
            _QuestionsCard(
              accent: _accent,
              questions: _questions,
              selected: _selected,
              showResults: _showResults,
              s: s,
              onChanged: (questionNumber, letter) =>
                  setState(() => _selected[questionNumber] = letter),
            ),
            const SizedBox(height: 16),

            // ─── Writing card ────────────────────────────────────────────
            Container(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.antwortbogen,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        s.woerterCount(_wordCount, _maxWords),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _wordCount > _maxWords
                              ? const Color(0xFFC62828)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (_timerStarted) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _timerExpired
                              ? Icons.timer_off
                              : Icons.timer_outlined,
                          size: 14,
                          color: _timerExpired
                              ? const Color(0xFFC62828)
                              : _secondsLeft < 120
                                  ? const Color(0xFFE65100)
                                  : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timerExpired ? s.zeitAbgelaufen : _timerDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _timerExpired
                                ? const Color(0xFFC62828)
                                : _secondsLeft < 120
                                    ? const Color(0xFFE65100)
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textController,
                    enabled: !_showResults,
                    maxLines: null,
                    minLines: 6,
                    style: const TextStyle(
                        fontSize: 14, height: 1.6, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: _timerStarted ? null : s.schreibenHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Action bar ───────────────────────────────────────────────
            if (!_showResults)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_questionsAnswered &&
                                _textController.text.trim().isNotEmpty)
                            ? _submit
                            : null,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(s.fertig,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: Text(s.antworten),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  _ScoreChip(correct: _correctCount, total: _questions.length, s: s),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: BorderSide(color: _accent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(s.neuVersuchen,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),

            // ─── Model answer, always visible ──────────────────────────
            if (_modelAnswerText.isNotEmpty) ...[
              const SizedBox(height: 16),
              _LetterCard(
                label: s.musterantwort,
                labelColor: _accent,
                backgroundColor: _accent.withValues(alpha: 0.04),
                borderColor: _accent.withValues(alpha: 0.3),
                text: _modelAnswerText,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Letter card ────────────────────────────────────────────────────────────

class _LetterCard extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Color backgroundColor;
  final Color borderColor;
  final String text;

  const _LetterCard({
    required this.label,
    required this.labelColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 14, height: 1.65, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ─── Questions card ─────────────────────────────────────────────────────────

class _QuestionsCard extends StatelessWidget {
  final Color accent;
  final List<Map<String, dynamic>> questions;
  final Map<int, String> selected;
  final bool showResults;
  final S s;
  final void Function(int number, String letter) onChanged;

  const _QuestionsCard({
    required this.accent,
    required this.questions,
    required this.selected,
    required this.showResults,
    required this.s,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.fragenZuDenTexten,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          for (var i = 0; i < questions.length; i++) ...[
            _QuestionBlock(
              accent: accent,
              question: questions[i],
              selected: selected[questions[i]['number'] as int],
              showResult: showResults,
              onChanged: showResults
                  ? null
                  : (letter) =>
                      onChanged(questions[i]['number'] as int, letter),
            ),
            if (i < questions.length - 1) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  final Color accent;
  final Map<String, dynamic> question;
  final String? selected;
  final bool showResult;
  final ValueChanged<String>? onChanged;

  const _QuestionBlock({
    required this.accent,
    required this.question,
    required this.selected,
    required this.showResult,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final number = question['number'];
    final stem = (question['text'] as String?) ?? '';
    final options =
        ((question['options'] as List?) ?? []).cast<Map<String, dynamic>>();
    final correct = (question['answer'] as String? ?? '').toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$number. ',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E)),
              ),
              TextSpan(
                text: stem,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final opt in options)
          _OptionTile(
            accent: accent,
            letter: (opt['letter'] as String?) ?? '',
            text: (opt['text'] as String?) ?? '',
            isSelected:
                selected?.toLowerCase() == (opt['letter'] as String?)?.toLowerCase(),
            showResult: showResult,
            isCorrect: (opt['letter'] as String?)?.toLowerCase() == correct,
            onTap: onChanged == null
                ? null
                : () => onChanged!((opt['letter'] as String?) ?? ''),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final Color accent;
  final String letter;
  final String text;
  final bool isSelected;
  final bool showResult;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.accent,
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.showResult,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Color borderColor = Colors.transparent;
    Color textColor = Colors.black87;
    Widget leading;

    if (showResult) {
      if (isCorrect) {
        bg = const Color(0xFF2E7D32).withValues(alpha: 0.1);
        borderColor = const Color(0xFF2E7D32).withValues(alpha: 0.4);
        textColor = const Color(0xFF1B5E20);
        leading =
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18);
      } else if (isSelected) {
        bg = const Color(0xFFC62828).withValues(alpha: 0.08);
        borderColor = const Color(0xFFC62828).withValues(alpha: 0.4);
        textColor = const Color(0xFF7F0000);
        leading = const Icon(Icons.cancel, color: Color(0xFFC62828), size: 18);
      } else {
        leading = Text('$letter)',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey));
      }
    } else if (isSelected) {
      bg = accent.withValues(alpha: 0.1);
      borderColor = accent.withValues(alpha: 0.4);
      textColor = accent;
      leading = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        child: Center(
          child: Text(letter,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      );
    } else {
      leading = Container(
        width: 18,
        height: 18,
        decoration:
            BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[400]!)),
        child: Center(
          child: Text(letter,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 13, color: textColor, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Score chip ─────────────────────────────────────────────────────────────

class _ScoreChip extends StatelessWidget {
  final int correct;
  final int total;
  final S s;

  const _ScoreChip({required this.correct, required this.total, required this.s});

  @override
  Widget build(BuildContext context) {
    final color = correct == total
        ? const Color(0xFF2E7D32)
        : correct >= 1
            ? const Color(0xFFE65100)
            : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(s.vonRichtig(correct, total),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}
