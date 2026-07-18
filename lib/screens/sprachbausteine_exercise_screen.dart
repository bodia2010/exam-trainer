import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/exercises/sprachbausteine1_variant.dart';
import '../services/course_storage.dart';
import '../ui/features/exercise/variant_loader.dart';
import '../widgets/favorite_button.dart';
import '../widgets/course_load_state.dart';

// ─── Text part model ───────────────────────────────────────────────────────────

enum _PartType { text, gap }

class _Part {
  final _PartType type;
  final String? textContent;
  final int? gapIndex; // 0-based position in text order
  final int? questionNumber; // original PDF marker, e.g. [31]

  const _Part.text(String t)
    : type = _PartType.text,
      textContent = t,
      gapIndex = null,
      questionNumber = null;

  const _Part.gap(int i, int n)
    : type = _PartType.gap,
      textContent = null,
      gapIndex = i,
      questionNumber = n;
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class SprachbausteineExerciseScreen extends StatefulWidget {
  final String courseId;
  final int index;
  final CourseLoader? courseLoader;
  const SprachbausteineExerciseScreen({
    super.key,
    required this.courseId,
    required this.index,
    this.courseLoader,
  });

  @override
  State<SprachbausteineExerciseScreen> createState() =>
      _SprachbausteineExerciseScreenState();
}

class _SprachbausteineExerciseScreenState
    extends State<SprachbausteineExerciseScreen> {
  static const _accent = Color(0xFF1565C0);

  SprachbausteineTeil1Variant? _variant;
  final _loadGuard = VariantLoadGuard();
  List<_Part> _parts = [];
  List<SprachbausteineOption> _words = []; // all_options
  List<int?> _selections = []; // indexed by gap position → word index in _words
  Map<int, int> _correctIndices = {}; // gapPosition → word index
  bool _showResults = false;
  bool _loading = true;
  CourseLoadFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SprachbausteineExerciseScreen oldWidget) {
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
      _words = [];
      _selections = [];
      _correctIndices = {};
      _showResults = false;
      _loading = true;
      _failure = null;
    });
    final result = await loadVariant<SprachbausteineTeil1Variant>(
      courseLoader: widget.courseLoader ?? CourseStorage.instance.loadAll,
      courseId: widget.courseId,
      sectionType: 'sprachbausteine_teil1',
      index: widget.index,
      fromJson: SprachbausteineTeil1Variant.fromJson,
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

  // The source PDF hard-wraps and hyphenates lines mid-word (e.g.
  // "Ausbildungs-" / "konzept"), and Gemini's extraction sometimes
  // preserves those raw line breaks — same artifact as the Hören
  // dialogue text, just showing up here as an ugly mid-word break
  // instead of a dropped sentence.
  String _dehyphenate(String text) =>
      text.replaceAllMapped(RegExp(r'(\w)-\n(\w)'), (m) => '${m[1]}${m[2]}');

  void _initExercise(SprachbausteineTeil1Variant v) {
    _words = v.allOptions;
    final answers = v.answers;
    final letterText = _dehyphenate(v.letterText);

    // Extract gap question numbers in order of appearance
    final gapNumbers = RegExp(
      r'\[(\d+)\]',
    ).allMatches(letterText).map((m) => int.parse(m.group(1)!)).toList();

    _selections = List.filled(gapNumbers.length, null);

    final wordByQuestionNumber = <int, String>{
      for (final a in answers)
        if (a.questionNumber != null && a.word != null)
          a.questionNumber!: a.word!,
    };
    _parts = _buildParts(letterText, gapNumbers, wordByQuestionNumber);

    // Map gapPosition → correct word index
    _correctIndices = {};
    for (int i = 0; i < gapNumbers.length; i++) {
      final qn = gapNumbers[i];
      SprachbausteineAnswer? answer;
      for (final a in answers) {
        if (a.questionNumber == qn) {
          answer = a;
          break;
        }
      }
      if (answer != null) {
        final letter = answer.letter;
        final idx = _words.indexWhere((w) => w.letter == letter);
        if (idx >= 0) _correctIndices[i] = idx;
      }
    }
  }

  List<_Part> _buildParts(
    String text,
    List<int> gapNumbers,
    Map<int, String> wordByQuestionNumber,
  ) {
    final gapPositions = <int, int>{};
    for (int i = 0; i < gapNumbers.length; i++) {
      gapPositions[gapNumbers[i]] = i;
    }
    final matches = RegExp(r'\[(\d+)\]').allMatches(text).toList();
    final parts = <_Part>[];
    int last = 0;
    for (var mi = 0; mi < matches.length; mi++) {
      final m = matches[mi];
      if (m.start > last) parts.add(_Part.text(text.substring(last, m.start)));
      final qn = int.parse(m.group(1)!);
      parts.add(_Part.gap(gapPositions[qn] ?? 0, qn));
      last = m.end;

      // The source PDF sometimes leaves the correct word written out right
      // after its own gap marker (an inline-answer-key artifact) — strip
      // it so the exercise doesn't give the answer away for free.
      final word = wordByQuestionNumber[qn];
      if (word != null && word.isNotEmpty) {
        final nextStart = mi + 1 < matches.length
            ? matches[mi + 1].start
            : text.length;
        final between = text.substring(last, nextStart);
        final leak = RegExp(
          '^\\s*${RegExp.escape(word)}\\b',
          caseSensitive: false,
        ).matchAsPrefix(between);
        if (leak != null) last += leak.end;
      }
    }
    if (last < text.length) parts.add(_Part.text(text.substring(last)));
    return parts;
  }

  void _selectWord(int gapIndex, int wordIndex) {
    setState(() {
      for (int i = 0; i < _selections.length; i++) {
        if (i != gapIndex && _selections[i] == wordIndex) _selections[i] = null;
      }
      _selections[gapIndex] = wordIndex;
    });
  }

  bool _isWordUsed(int wordIndex) => _selections.contains(wordIndex);

  bool get _allAnswered => _selections.every((s) => s != null);

  int get _correctCount {
    int n = 0;
    for (int i = 0; i < _selections.length; i++) {
      if (_selections[i] == _correctIndices[i]) n++;
    }
    return n;
  }

  Color get _scoreColor {
    final c = _correctCount;
    final total = _selections.length;
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
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: _GapWidget(
          gapIndex: part.gapIndex!,
          questionNumber: part.questionNumber!,
          words: _words,
          selections: _selections,
          correctIndices: _correctIndices,
          showResults: _showResults,
          onSelect: _selectWord,
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
    final total = _selections.length;

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
            if (topic.isNotEmpty)
              Text(
                topic,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          FavoriteButton(
            favId:
                '/course/${widget.courseId}/sprachbausteine_teil1/${widget.index}',
            title: version.isEmpty
                ? s.variante(varNum)
                : s.varianteMitVersion(varNum, version),
            subtitle: 'Sprachbausteine Teil 1',
            route:
                '/course/${widget.courseId}/sprachbausteine_teil1/${widget.index}',
            courseId: widget.courseId,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Letter card ──────────────────────────────────────────────
            _card(child: Text.rich(TextSpan(children: _buildSpans()))),

            const SizedBox(height: 16),

            // ─── Word bank ────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.wortliste,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _words.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _WordRow(word: _words[i], isUsed: _isWordUsed(i)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Action bar ───────────────────────────────────────────────
            if (!_showResults)
              SizedBox(
                width: double.infinity,
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                        _selections = List.filled(_selections.length, null);
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

// ─── Word row in word bank ─────────────────────────────────────────────────────

class _WordRow extends StatelessWidget {
  final SprachbausteineOption word;
  final bool isUsed;

  const _WordRow({required this.word, required this.isUsed});

  @override
  Widget build(BuildContext context) {
    final letter = word.displayLetter;
    final text = word.text;
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 8,
          color: isUsed ? Colors.grey[400] : const Color(0xFF1565C0),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$letter)  $text',
            style: TextStyle(
              fontSize: 15,
              decoration: isUsed
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: isUsed ? Colors.grey[400] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Inline gap widget ─────────────────────────────────────────────────────────

class _GapWidget extends StatelessWidget {
  final int gapIndex;
  final int questionNumber;
  final List<SprachbausteineOption> words;
  final List<int?> selections;
  final Map<int, int> correctIndices;
  final bool showResults;
  final void Function(int gapIndex, int wordIndex) onSelect;

  const _GapWidget({
    required this.gapIndex,
    required this.questionNumber,
    required this.words,
    required this.selections,
    required this.correctIndices,
    required this.showResults,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selectedWordIndex = gapIndex < selections.length
        ? selections[gapIndex]
        : null;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final selectedText = selectedWordIndex == null
        ? null
        : words[selectedWordIndex].text;
    // Size the inline control from the actual selected word. Short answers
    // should read like part of the sentence, while long answers remain
    // bounded and are exposed in full through semantics/dropdown value.
    final maxSelectedWidth = textScale >= 1.5 ? 104.0 : 124.0;
    final selectedItemWidth = selectedText == null
        ? 52.0
        : (selectedText.length * 7.2 * textScale + 34).clamp(
            58.0,
            maxSelectedWidth,
          );
    final menuWidth = (MediaQuery.sizeOf(context).width - 32).clamp(
      160.0,
      320.0,
    );

    if (showResults) {
      // Nothing was picked — show the correct word instead of leaving a
      // blank, so "Antworten zeigen" actually reveals the answer here too.
      // It gets its own neutral (blue) style: not a green "you got it
      // right" nor a red "you got it wrong" you never actually chose.
      final unanswered = selectedWordIndex == null;
      final displayIndex = selectedWordIndex ?? correctIndices[gapIndex];
      if (displayIndex == null) {
        return const Text(
          '___',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        );
      }
      final isCorrect =
          !unanswered && selectedWordIndex == correctIndices[gapIndex];
      final word = words[displayIndex];
      final wordText = word.text;
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
          wordText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
    }

    // Inline dropdown
    return Semantics(
      container: true,
      label: S.of(context).lueckeAuswaehlen(questionNumber),
      value: selectedText,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        constraints: const BoxConstraints(minHeight: 48),
        child: DropdownButton<int>(
          value: selectedWordIndex,
          hint: const Text(
            '___',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          isDense: true,
          menuWidth: menuWidth,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          underline: Container(height: 1, color: const Color(0xFF1565C0)),
          onChanged: (v) {
            if (v != null) onSelect(gapIndex, v);
          },
          items: [
            for (int i = 0; i < words.length; i++)
              DropdownMenuItem<int>(
                value: i,
                child: Builder(
                  builder: (context) {
                    final usedAt = selections.indexOf(i);
                    final usedByOther = usedAt >= 0 && usedAt != gapIndex;
                    return Text(
                      words[i].text,
                      style: TextStyle(
                        fontSize: 15,
                        color: usedByOther ? Colors.grey[400] : Colors.black87,
                        fontStyle: usedByOther
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    );
                  },
                ),
              ),
          ],
          selectedItemBuilder: (context) => [
            for (final word in words)
              SizedBox(
                width: selectedItemWidth,
                child: Text(
                  word.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
