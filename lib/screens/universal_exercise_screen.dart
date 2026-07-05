import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/parsed_course.dart' show sectionLabels, sectionMeta;
import '../services/course_storage.dart';

/// Renders any section parsed with the universal schema. Design and
/// behaviour ported from deutch-lernen's Lesen Teil 1 exercise screen:
/// instruction banner, section headers, expandable text cards, question
/// cards with letter-button rows, result banner and a fixed bottom bar.
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
  static const _navy = Color(0xFF1A237E);
  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFD32F2F);

  Map<String, dynamic>? _variant;
  final Map<int, String> _selected = {}; // question number → answer
  bool _showResults = false;

  Color get _accent =>
      sectionMeta[widget.sectionType]?.color ?? const Color(0xFF00838F);

  String get _instruction => switch (widget.sectionType) {
        'lesen_teil1' =>
          'Lesen Sie die Texte. Welcher Text passt zu welcher Person? '
              'Nicht alle Texte werden gebraucht.',
        'lesen_teil2' => 'Lesen Sie den Text und lösen Sie die Aufgaben.',
        'lesen_teil3' =>
          'Welche Antwort passt zu welcher Situation? '
              '„x" bedeutet: kein Text passt.',
        'lesen_teil4' =>
          'Lesen Sie das Protokoll und lösen Sie die Aufgaben.',
        'beschwerde' =>
          'Lesen Sie die Briefe und lösen Sie die Aufgaben. '
              'Die Musterantwort ist ein Beispiel für den Schreibteil.',
        'sprachbausteine_teil2' =>
          'Wählen Sie für jede Lücke die richtige Lösung.',
        'hoeren_teil2' =>
          'Hören Sie die Gespräche. Welche Aussage passt zu welchem Gespräch?',
        'hoeren_teil3' =>
          'Hören Sie das Gespräch und lösen Sie die Aufgaben.',
        'hoeren_teil4' =>
          'Hören Sie die Nachrichten und lösen Sie die Aufgaben.',
        _ => 'Lösen Sie die Aufgaben.',
      };

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

  bool _isCorrect(Map<String, dynamic> q) =>
      _selected[_qNumber(q)] != null &&
      _normalized(_selected[_qNumber(q)]) == _normalized(q['answer']);

  int get _score => _questions.where(_isCorrect).length;

  bool get _isHoeren => widget.sectionType.startsWith('hoeren');

  void _check() {
    if (_selected.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte alle Aufgaben beantworten.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _showResults = true);
  }

  void _reset() {
    setState(() {
      _selected.clear();
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = _variant;
    if (v == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final varNum = v['variant_number'] ?? (widget.index + 1);
    final topic = (v['topic'] as String?) ?? '';
    final version = (v['version'] as String?) ?? '';
    final audioUrl = v['audio_url'] as String?;
    final label = sectionLabels[widget.sectionType] ?? widget.sectionType;
    final subtitle = [
      label,
      if (version.isNotEmpty) version,
      if (topic.isNotEmpty) topic,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вариант $varNum',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          if (_showResults)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '$_score / ${_questions.length}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _buildInstruction(),
                  if (audioUrl != null && audioUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _audioButton(audioUrl),
                  ],
                  if (_texts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(
                        label: _isHoeren ? 'Transkript' : 'Texte lesen',
                        icon: Icons.article_outlined,
                        accent: _accent),
                    const SizedBox(height: 10),
                    ..._texts.map((t) => _TextCard(
                          title: (t['title'] as String?) ?? 'Текст',
                          content: (t['content'] as String?) ?? '',
                          accent: _accent,
                          initiallyExpanded: !_isHoeren && _texts.length == 1,
                        )),
                  ],
                  if (_showPool) ...[
                    const SizedBox(height: 16),
                    _poolCard(),
                  ],
                  const SizedBox(height: 20),
                  _SectionHeader(
                      label: 'Aufgaben',
                      icon: Icons.checklist_rounded,
                      accent: _accent),
                  const SizedBox(height: 10),
                  ..._questions.map(_questionCard),
                  const SizedBox(height: 8),
                  if (_showResults) _buildResultBanner(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        _instruction,
        style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.45),
      ),
    );
  }

  Widget _audioButton(String url) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.play_circle_outline),
      label: const Text('Слушать запись'),
    );
  }

  // The pool card duplicates the texts section for Lesen matching (letters
  // a-h are the texts themselves) — show it only when the pool holds
  // options that are NOT represented as texts (e.g. Hören Teil 2).
  bool get _showPool =>
      _optionPool.isNotEmpty && _texts.length < _optionPool.length - 1;

  Widget _poolCard() {
    final used = _selected.values.map(_normalized).toSet();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AUSSAGEN',
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle,
                      size: 8, color: isUsed ? Colors.grey[400] : _accent),
                  const SizedBox(width: 8),
                  Expanded(
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
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── question cards ───────────────────────────────────────────────────────

  Widget _questionCard(Map<String, dynamic> q) {
    final type = (q['type'] as String?) ?? 'choice';
    final num = _qNumber(q);
    final selected = _selected[num];
    final correct = _showResults && selected != null ? _isCorrect(q) : null;

    Color borderColor = const Color(0xFFE0E0E0);
    if (correct != null) borderColor = correct ? _green : _red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _questionHeader(q, correct),
            const SizedBox(height: 12),
            switch (type) {
              'true_false' => _tfButtons(q),
              'match' => _letterRows(
                  q,
                  _optionPool
                      .map((o) => (o['letter'] as String?) ?? '')
                      .toList()),
              _ => _choiceOptions(q),
            },
            if (correct == false) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 14, color: _green),
                  const SizedBox(width: 4),
                  Text(
                    'Richtig: ${q['answer'].toString().toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _questionHeader(Map<String, dynamic> q, bool? correct) {
    final num = _qNumber(q);
    final text = (q['text'] as String?) ?? '';
    // Statements usually start with the person's name — set it in bold.
    final spaceIdx = text.indexOf(' ');
    final head = spaceIdx > 0 ? text.substring(0, spaceIdx) : text;
    final tail = spaceIdx > 0 ? text.substring(spaceIdx) : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$num',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _navy),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF212121), height: 1.4),
              children: [
                TextSpan(
                    text: head,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: tail),
              ],
            ),
          ),
        ),
        if (correct != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              correct ? Icons.check_circle : Icons.cancel,
              color: correct ? _green : _red,
              size: 22,
            ),
          ),
      ],
    );
  }

  Widget _tfButtons(Map<String, dynamic> q) {
    final num = _qNumber(q);
    final selected = _selected[num];
    final correct = _normalized(q['answer']);
    Widget button(String value, String label) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _AnswerButton(
            label: label,
            selected: selected == value,
            showResult: _showResults,
            isCorrect: value == correct,
            navy: _navy,
            onTap: _showResults
                ? null
                : () => setState(() => _selected[num] = value),
          ),
        ),
      );
    }

    return Row(children: [
      button('richtig', 'Richtig'),
      button('falsch', 'Falsch'),
    ]);
  }

  Widget _letterRows(Map<String, dynamic> q, List<String> letters) {
    final num = _qNumber(q);
    final selected = _selected[num];
    final correct = _normalized(q['answer']);

    final rows = <List<String>>[];
    for (var i = 0; i < letters.length; i += 4) {
      rows.add(letters.sublist(i, (i + 4).clamp(0, letters.length)));
    }

    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              for (final l in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _AnswerButton(
                      label: l,
                      selected: selected != null &&
                          _normalized(selected) == _normalized(l),
                      showResult: _showResults,
                      isCorrect: _normalized(l) == correct,
                      navy: _navy,
                      onTap: _showResults
                          ? null
                          : () => setState(() => _selected[num] = l),
                    ),
                  ),
                ),
              // pad short rows so buttons keep equal width
              for (var i = row.length; i < 4; i++) const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _choiceOptions(Map<String, dynamic> q) {
    final num = _qNumber(q);
    final options =
        ((q['options'] as List?) ?? []).cast<Map<String, dynamic>>();
    final correct = _normalized(q['answer']);
    final selected = _selected[num];

    return Column(
      children: options.map((opt) {
        final letter = (opt['letter'] as String?) ?? '';
        final optText = (opt['text'] as String?) ?? '';
        final isSelected =
            selected != null && _normalized(selected) == _normalized(letter);
        final isCorrect = _normalized(letter) == correct;

        Color bg = const Color(0xFFF5F7FF);
        Color fg = const Color(0xFF37474F);
        Color borderColor = const Color(0xFFCFD8DC);
        FontWeight weight = FontWeight.w400;
        if (isSelected) {
          if (_showResults) {
            bg = isCorrect ? _green : _red;
            fg = Colors.white;
            borderColor = Colors.transparent;
          } else {
            bg = _navy;
            fg = Colors.white;
            borderColor = Colors.transparent;
          }
          weight = FontWeight.w600;
        } else if (_showResults && isCorrect) {
          bg = const Color(0xFFE8F5E9);
          fg = _green;
          borderColor = _green;
          weight = FontWeight.w600;
        }

        return GestureDetector(
          onTap: _showResults
              ? null
              : () => setState(() => _selected[num] = letter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Text('$letter) $optText',
                style:
                    TextStyle(color: fg, fontSize: 14, fontWeight: weight)),
          ),
        );
      }).toList(),
    );
  }

  // ─── result banner + bottom bar ───────────────────────────────────────────

  Widget _buildResultBanner() {
    final all = _questions.length;
    final correct = _score;
    final color = correct == all
        ? const Color(0xFF1B5E20)
        : correct >= all ~/ 2
            ? const Color(0xFFF57F17)
            : const Color(0xFFB71C1C);
    final bg = correct == all
        ? const Color(0xFFE8F5E9)
        : correct >= all ~/ 2
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            correct == all ? Icons.emoji_events : Icons.bar_chart,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$correct von $all richtig',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                correct == all
                    ? 'Ausgezeichnet! Alles richtig!'
                    : 'Schauen Sie die falschen Antworten an.',
                style: TextStyle(
                    fontSize: 13, color: color.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
      child: Row(
        children: [
          if (_showResults)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Neu versuchen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: BorderSide(color: _accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _check,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Prüfen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _SectionHeader(
      {required this.label, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }
}

class _TextCard extends StatefulWidget {
  final String title;
  final String content;
  final Color accent;
  final bool initiallyExpanded;

  const _TextCard({
    required this.title,
    required this.content,
    required this.accent,
    this.initiallyExpanded = false,
  });

  @override
  State<_TextCard> createState() => _TextCardState();
}

class _TextCardState extends State<_TextCard> {
  late bool _expanded = widget.initiallyExpanded;

  // "a) Auf ins Abenteuer!" → badge "a", title "Auf ins Abenteuer!"
  (String, String) get _badgeAndTitle {
    final m = RegExp(r'^([a-zA-Zа-яА-Я])\)\s*(.+)$').firstMatch(widget.title);
    if (m != null) return (m.group(1)!, m.group(2)!);
    return ('', widget.title);
  }

  @override
  Widget build(BuildContext context) {
    final (badge, title) = _badgeAndTitle;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (badge.isNotEmpty) ...[
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: widget.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    widget.content,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool showResult;
  final bool isCorrect;
  final Color navy;
  final VoidCallback? onTap;

  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.showResult,
    required this.isCorrect,
    required this.navy,
    required this.onTap,
  });

  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFD32F2F);

  Color get _bgColor {
    if (!selected && !(showResult && isCorrect)) return const Color(0xFFF5F7FF);
    if (showResult) {
      if (selected && isCorrect) return _green;
      if (selected && !isCorrect) return _red;
      if (!selected && isCorrect) return const Color(0xFFE8F5E9);
    }
    return navy;
  }

  Color get _textColor {
    if (!selected && !(showResult && isCorrect)) return const Color(0xFF37474F);
    if (showResult) {
      if (selected) return Colors.white;
      if (isCorrect) return _green;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : showResult && isCorrect
                    ? _green
                    : const Color(0xFFCFD8DC),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
      ),
    );
  }
}
