import 'package:flutter/material.dart';
import '../services/course_storage.dart';

// ─── Text part model ───────────────────────────────────────────────────────────

enum _PartType { text, gap }

class _Part {
  final _PartType type;
  final String? textContent;
  final int? gapIndex; // 0-based position in text order

  const _Part.text(String t)
      : type = _PartType.text,
        textContent = t,
        gapIndex = null;

  const _Part.gap(int i)
      : type = _PartType.gap,
        textContent = null,
        gapIndex = i;
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class SprachbausteineExerciseScreen extends StatefulWidget {
  final String courseId;
  final int index;
  const SprachbausteineExerciseScreen({
    super.key,
    required this.courseId,
    required this.index,
  });

  @override
  State<SprachbausteineExerciseScreen> createState() =>
      _SprachbausteineExerciseScreenState();
}

class _SprachbausteineExerciseScreenState
    extends State<SprachbausteineExerciseScreen> {
  static const _accent = Color(0xFF1565C0);

  Map<String, dynamic>? _variant;
  List<_Part> _parts = [];
  List<Map<String, dynamic>> _words = []; // all_options
  List<int?> _selections = []; // indexed by gap position → word index in _words
  Map<int, int> _correctIndices = {}; // gapPosition → word index
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
        final variants = course.sections['sprachbausteine_teil1'] ?? [];
        if (widget.index < variants.length) {
          final v = variants[widget.index] as Map<String, dynamic>;
          _initExercise(v);
          if (mounted) setState(() => _variant = v);
        }
      }
    } catch (_) {}
  }

  void _initExercise(Map<String, dynamic> v) {
    _words = (v['all_options'] as List? ?? []).cast<Map<String, dynamic>>();
    final answers = (v['answers'] as List? ?? []).cast<Map<String, dynamic>>();
    final letterText = v['letter_text'] as String? ?? '';

    // Extract gap question numbers in order of appearance
    final gapNumbers = RegExp(r'\[(\d+)\]')
        .allMatches(letterText)
        .map((m) => int.parse(m.group(1)!))
        .toList();

    _selections = List.filled(gapNumbers.length, null);
    _parts = _buildParts(letterText, gapNumbers);

    // Map gapPosition → correct word index
    _correctIndices = {};
    for (int i = 0; i < gapNumbers.length; i++) {
      final qn = gapNumbers[i];
      final answer = answers.firstWhere(
        (a) => (a['question_number'] as num?)?.toInt() == qn,
        orElse: () => {},
      );
      if (answer.isNotEmpty) {
        final letter = answer['letter'] as String?;
        final idx = _words.indexWhere((w) => w['letter'] == letter);
        if (idx >= 0) _correctIndices[i] = idx;
      }
    }
  }

  List<_Part> _buildParts(String text, List<int> gapNumbers) {
    final gapPositions = <int, int>{};
    for (int i = 0; i < gapNumbers.length; i++) {
      gapPositions[gapNumbers[i]] = i;
    }
    final parts = <_Part>[];
    int last = 0;
    for (final m in RegExp(r'\[(\d+)\]').allMatches(text)) {
      if (m.start > last) parts.add(_Part.text(text.substring(last, m.start)));
      final qn = int.parse(m.group(1)!);
      parts.add(_Part.gap(gapPositions[qn] ?? 0));
      last = m.end;
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
    const bodyStyle =
        TextStyle(fontSize: 15, color: Colors.black87, height: 1.6);
    return _parts.map((part) {
      if (part.type == _PartType.text) {
        return TextSpan(text: part.textContent, style: bodyStyle);
      }
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _GapWidget(
          gapIndex: part.gapIndex!,
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
    final v = _variant;
    if (v == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final varNum = v['variant_number'] ?? (widget.index + 1);
    final topic = v['topic'] as String? ?? '';
    final version = (v['version'] as String?) ?? '';
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
                    ? 'Вариант $varNum'
                    : 'Вариант $varNum · $version',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Letter card ──────────────────────────────────────────────
            _card(
              child: RichText(
                text: TextSpan(children: _buildSpans()),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Word bank ────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WORTLISTE',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _accent,
                          letterSpacing: 0.5)),
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
                        label: const Text('Prüfen',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: _scoreColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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

// ─── Word row in word bank ─────────────────────────────────────────────────────

class _WordRow extends StatelessWidget {
  final Map<String, dynamic> word;
  final bool isUsed;

  const _WordRow({required this.word, required this.isUsed});

  @override
  Widget build(BuildContext context) {
    final letter = word['letter'] as String? ?? '';
    final text = word['text'] as String? ?? '';
    return Row(
      children: [
        Icon(Icons.circle,
            size: 8,
            color: isUsed ? Colors.grey[400] : const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$letter)  $text',
            style: TextStyle(
              fontSize: 15,
              decoration:
                  isUsed ? TextDecoration.lineThrough : TextDecoration.none,
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
  final List<Map<String, dynamic>> words;
  final List<int?> selections;
  final Map<int, int> correctIndices;
  final bool showResults;
  final void Function(int gapIndex, int wordIndex) onSelect;

  const _GapWidget({
    required this.gapIndex,
    required this.words,
    required this.selections,
    required this.correctIndices,
    required this.showResults,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selectedWordIndex =
        gapIndex < selections.length ? selections[gapIndex] : null;

    if (showResults) {
      // Nothing was picked — show the correct word instead of leaving a
      // blank, so "Antworten zeigen" actually reveals the answer here too.
      // It gets its own neutral (blue) style: not a green "you got it
      // right" nor a red "you got it wrong" you never actually chose.
      final unanswered = selectedWordIndex == null;
      final displayIndex = selectedWordIndex ?? correctIndices[gapIndex];
      if (displayIndex == null) {
        return const Text('___',
            style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500));
      }
      final isCorrect = !unanswered && selectedWordIndex == correctIndices[gapIndex];
      final word = words[displayIndex];
      final wordText = word['text'] as String? ?? '';
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
        ),
      );
    }

    // Inline dropdown
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: DropdownButton<int>(
        value: selectedWordIndex,
        hint: const Text('___',
            style: TextStyle(fontSize: 15, color: Colors.grey)),
        isDense: true,
        underline: Container(height: 1, color: const Color(0xFF1565C0)),
        onChanged: (v) {
          if (v != null) onSelect(gapIndex, v);
        },
        items: [
          for (int i = 0; i < words.length; i++)
            DropdownMenuItem<int>(
              value: i,
              child: Builder(builder: (context) {
                final usedAt = selections.indexOf(i);
                final usedByOther = usedAt >= 0 && usedAt != gapIndex;
                return Text(
                  words[i]['text'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: usedByOther ? Colors.grey[400] : Colors.black87,
                    fontStyle:
                        usedByOther ? FontStyle.italic : FontStyle.normal,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
