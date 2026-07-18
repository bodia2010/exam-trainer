import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/exercises/exercise_common.dart';
import '../models/exercises/universal_variant.dart';
import '../services/course_storage.dart';
import '../ui/features/exercise/variant_loader.dart';
import '../widgets/favorite_button.dart';
import '../widgets/course_load_state.dart';

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
  final CourseLoader? courseLoader;
  const Sprachbausteine2ExerciseScreen({
    super.key,
    required this.courseId,
    required this.index,
    this.courseLoader,
  });

  @override
  State<Sprachbausteine2ExerciseScreen> createState() =>
      _Sprachbausteine2ExerciseScreenState();
}

class _Sprachbausteine2ExerciseScreenState
    extends State<Sprachbausteine2ExerciseScreen> {
  static const _accent = Color(0xFF5E35B1);

  UniversalVariant? _variant;
  final _loadGuard = VariantLoadGuard();
  List<_Part> _parts = [];
  Map<int, ExerciseQuestion> _questionsByNumber = {};
  final Map<int, String> _selections = {}; // questionNumber -> letter
  bool _showResults = false;
  bool _loading = true;
  CourseLoadFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant Sprachbausteine2ExerciseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId ||
        oldWidget.index != widget.index ||
        oldWidget.courseLoader != widget.courseLoader) {
      _load();
    }
  }

  @override
  void dispose() {
    _loadGuard.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = _loadGuard.begin();
    setState(() {
      _variant = null;
      _parts = [];
      _questionsByNumber = {};
      _selections.clear();
      _showResults = false;
      _loading = true;
      _failure = null;
    });
    final result = await loadVariant<UniversalVariant>(
      courseLoader: widget.courseLoader ?? CourseStorage.instance.loadAll,
      courseId: widget.courseId,
      sectionType: 'sprachbausteine_teil2',
      index: widget.index,
      fromJson: UniversalVariant.fromJson,
    );
    if (!mounted || !_loadGuard.isCurrent(generation)) return;
    var variant = result.variant;
    var failure = result.failure;
    if (variant != null) {
      // _initExercise's regex/gap-marker parsing runs against real text
      // content, not raw dynamic JSON, but still degrades to the same
      // error state as a parse failure rather than crashing the tree.
      try {
        _initExercise(variant);
      } catch (_) {
        variant = null;
        failure = CourseLoadFailure.error;
      }
    }
    setState(() {
      _variant = variant;
      _failure = failure;
      _loading = false;
    });
  }

  void _initExercise(UniversalVariant v) {
    final texts = v.texts;
    final content = _dehyphenate(texts.isNotEmpty ? texts[0].content : '');
    _questionsByNumber = {for (final q in v.questions) q.number: q};
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
      final correctLetter = q?.answer;
      final options = q?.options ?? const <ExerciseOption>[];
      ExerciseOption? matchingOption;
      for (final o in options) {
        if (o.letter == correctLetter) {
          matchingOption = o;
          break;
        }
      }
      final correctWord = correctLetter == null ? null : matchingOption?.text;
      if (correctWord != null && correctWord.isNotEmpty) {
        final nextStart = mi + 1 < matches.length
            ? matches[mi + 1].start
            : text.length;
        final between = text.substring(last, nextStart);
        final leak = RegExp(
          '^\\s*${RegExp.escape(correctWord)}\\b',
          caseSensitive: false,
        ).matchAsPrefix(between);
        if (leak != null) last += leak.end;
      }
    }
    if (last < text.length) parts.add(_Part.text(text.substring(last)));
    return parts;
  }

  bool get _allAnswered =>
      _questionsByNumber.keys.every((n) => _selections.containsKey(n));

  int get _correctCount => _questionsByNumber.keys
      .where((n) => _selections[n] == _questionsByNumber[n]!.answer)
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
    const bodyStyle = TextStyle(
      fontSize: 15,
      color: Colors.black87,
      height: 1.6,
    );
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
    final s = S.of(context);
    final v = _variant;
    if (v == null) {
      return CourseLoadScaffold(
        loading: _loading,
        failure: _failure,
        onRetry: _load,
        accent: _accent,
      );
    }

    final varNum = v.displayNumber(widget.index);
    final topic = v.topic;
    final version = v.version;
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
                  ? s.variante(varNum)
                  : s.varianteMitVersion(varNum, version),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Sprachbausteine Teil 2${topic.isNotEmpty ? ' · $topic' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          FavoriteButton(
            favId:
                '/course/${widget.courseId}/sprachbausteine_teil2/${widget.index}',
            title: version.isEmpty
                ? s.variante(varNum)
                : s.varianteMitVersion(varNum, version),
            subtitle: 'Sprachbausteine Teil 2',
            route:
                '/course/${widget.courseId}/sprachbausteine_teil2/${widget.index}',
            courseId: widget.courseId,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(child: Text.rich(TextSpan(children: _buildSpans()))),
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
                        label: Text(
                          s.pruefen,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showResults = true),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: Text(s.antworten),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Chip(
                    label: Text(
                      s.vonRichtig(_correctCount, total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: _scoreColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        s.neuVersuchen,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  final ExerciseQuestion question;
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
    final options = question.options;
    final correct = question.answer;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final selectedItemWidth = largeText ? 112.0 : 140.0;
    final menuWidth = (MediaQuery.sizeOf(context).width - 32).clamp(
      160.0,
      320.0,
    );

    if (showResults) {
      // Nothing was picked — show the correct option instead of leaving a
      // blank, so "Antworten zeigen" actually reveals the answer here too.
      final unanswered = selected == null;
      final displayLetter = selected ?? correct;
      if (displayLetter == null) {
        return const Text(
          '___',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        );
      }
      final isCorrect = !unanswered && selected == correct;
      ExerciseOption? matched;
      for (final o in options) {
        if (o.letter == displayLetter) {
          matched = o;
          break;
        }
      }
      final selectedText = matched?.text ?? displayLetter;
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

    return Semantics(
      container: true,
      label: S.of(context).lueckeAuswaehlen(question.number),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        child: DropdownButton<String>(
          value: selected,
          hint: const Text(
            '___',
            style: TextStyle(fontSize: 14, color: _accent),
          ),
          isDense: true,
          menuWidth: menuWidth,
          underline: Container(height: 1, color: _accent),
          onChanged: (v) {
            if (v != null) onSelect(v);
          },
          items: options.map((opt) {
            final letter = opt.letter;
            final text = opt.text;
            return DropdownMenuItem<String>(
              value: letter,
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) => options
              .map(
                (option) => SizedBox(
                  width: selectedItemWidth,
                  child: Text(
                    option.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
