import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../models/exercises/exercise_common.dart';
import '../models/exercises/universal_variant.dart';
import '../models/parsed_course.dart' show sectionLabels, sectionMeta;
import '../models/voice_gender.dart';
import '../services/course_storage.dart';
import '../ui/core/theme/exam_theme.dart';
import '../ui/features/exercise/variant_loader.dart';
import '../widgets/dialogue_audio_player.dart';
import '../widgets/favorite_button.dart';
import '../widgets/course_load_state.dart';

/// Renders any section parsed with the universal schema. Design and
/// behaviour ported from deutch-lernen's Lesen Teil 1 exercise screen:
/// instruction banner, section headers, expandable text cards, question
/// cards with letter-button rows, result banner and a fixed bottom bar.
class UniversalExerciseScreen extends StatefulWidget {
  final String courseId;
  final String sectionType;
  final int index;
  final CourseLoader? courseLoader;
  const UniversalExerciseScreen({
    super.key,
    required this.courseId,
    required this.sectionType,
    required this.index,
    this.courseLoader,
  });

  @override
  State<UniversalExerciseScreen> createState() =>
      _UniversalExerciseScreenState();
}

class _UniversalExerciseScreenState extends State<UniversalExerciseScreen> {
  static const _navy = ExamColors.ink;
  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFD32F2F);

  UniversalVariant? _variant;
  final Map<int, String> _selected = {}; // question number → answer
  bool _showResults = false;
  bool _loading = true;
  CourseLoadFailure? _failure;

  Color get _accent =>
      sectionMeta[widget.sectionType]?.color ?? const Color(0xFF00838F);

  List<ExerciseQuestion> get _questions => _variant?.questions ?? const [];

  List<ExerciseOption> get _optionPool => _variant?.optionPool ?? const [];

  List<ExerciseText> get _texts => _variant?.texts ?? const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final result = await loadVariant<UniversalVariant>(
      courseLoader: widget.courseLoader ?? CourseStorage.instance.loadAll,
      courseId: widget.courseId,
      sectionType: widget.sectionType,
      index: widget.index,
      fromJson: (json) => UniversalVariant.fromJson(
        json,
        sectionType: widget.sectionType,
        variantIndex: widget.index,
      ),
    );
    if (!mounted) return;
    setState(() {
      _variant = result.variant;
      _failure = result.failure;
      _loading = false;
    });
  }

  // The source PDF sometimes writes answer letters in Cyrillic lookalikes
  // ("с (100%)" with Cyrillic с) — map them to Latin before comparing.
  static const _cyrillicLookalikes = {
    'а': 'a',
    'в': 'b',
    'с': 'c',
    'е': 'e',
    'о': 'o',
    'р': 'p',
    'х': 'x',
    'к': 'k',
    'м': 'm',
    'т': 't',
  };

  String _normalized(Object? answer) {
    final s = answer.toString().trim().toLowerCase();
    return s.split('').map((ch) => _cyrillicLookalikes[ch] ?? ch).join();
  }

  bool _isCorrect(ExerciseQuestion q) =>
      _selected[q.number] != null &&
      _normalized(_selected[q.number]) == _normalized(q.answer);

  int get _score => _questions.where(_isCorrect).length;

  bool get _isHoeren => widget.sectionType.startsWith('hoeren');

  /// Excludes questions the source had no real answer for (see
  /// _questionCard's kNoAnswerSentinel) — those never get an interactive
  /// widget to select an answer in, so requiring one before "Prüfen"
  /// works would permanently lock the student out of an exercise that
  /// happens to contain one.
  Iterable<ExerciseQuestion> get _answerableQuestions =>
      _questions.where((q) => q.answer != kNoAnswerSentinel);

  void _check() {
    if (_selected.length < _answerableQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).bitteAlleAufgabenBeantworten),
          duration: const Duration(seconds: 2),
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
      return CourseLoadScaffold(
        loading: _loading,
        failure: _failure,
        onRetry: _load,
      );
    }

    final s = S.of(context);
    final varNum = v.displayNumber(widget.index);
    final topic = v.topic;
    final version = v.version;
    final audioUrl = v.audioUrl;
    final label = sectionLabels[widget.sectionType] ?? widget.sectionType;
    final subtitle = [
      label,
      if (version.isNotEmpty) version,
      if (topic.isNotEmpty) topic,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ExamColors.canvas,
        foregroundColor: ExamColors.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.variante(varNum),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: ExamColors.inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          FavoriteButton(
            favId:
                '/course/${widget.courseId}/${widget.sectionType}/${widget.index}',
            title: s.variante(varNum),
            subtitle: subtitle,
            route:
                '/course/${widget.courseId}/${widget.sectionType}/${widget.index}',
            courseId: widget.courseId,
          ),
          if (_showResults)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '$_score / ${_answerableQuestions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ExamColors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: ExamColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _buildInstruction(s),
                  if (audioUrl != null && audioUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _audioButton(audioUrl, s),
                  ],
                  if (_texts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(
                      label: _isHoeren ? s.transkript : s.texteLesen,
                      icon: Icons.article_outlined,
                      accent: _accent,
                    ),
                    const SizedBox(height: 10),
                    ..._texts.asMap().entries.map(
                      (e) => _TextCard(
                        key: ValueKey('text_${e.key}'),
                        title: e.value.title ?? s.text,
                        content: e.value.content,
                        accent: _accent,
                        recordingId: scopedVoiceRecordingId(
                          widget.courseId,
                          e.value.recordingId,
                        ),
                        voiceMetadata: e.value.voiceMetadata,
                        initiallyExpanded: !_isHoeren && _texts.length == 1,
                        showAudioPlayer: _isHoeren,
                      ),
                    ),
                  ],
                  if (_showPool) ...[const SizedBox(height: 16), _poolCard(s)],
                  const SizedBox(height: 20),
                  _SectionHeader(
                    label: s.aufgaben,
                    icon: Icons.checklist_rounded,
                    accent: _accent,
                  ),
                  const SizedBox(height: 10),
                  ..._questions.map(_questionCard),
                  const SizedBox(height: 8),
                  if (_showResults) _buildResultBanner(s),
                ],
              ),
            ),
            _buildBottomBar(s),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(S s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        s.instruktion(widget.sectionType),
        style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.45),
      ),
    );
  }

  Widget _audioButton(String url, S s) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.play_circle_outline),
      label: Text(s.aufnahmeAnhoeren),
    );
  }

  // The pool card duplicates the texts section for Lesen matching (letters
  // a-h are the texts themselves) — show it only when the pool holds
  // options that are NOT represented as texts (e.g. Hören Teil 2).
  bool get _showPool =>
      _optionPool.isNotEmpty && _texts.length < _optionPool.length - 1;

  Widget _poolCard(S s) {
    final used = _selected.values.map(_normalized).toSet();
    return Container(
      decoration: BoxDecoration(
        color: ExamColors.surface,
        borderRadius: BorderRadius.circular(ExamRadius.medium),
        border: Border.all(color: ExamColors.border),
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
          Text(
            s.aussagen,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _accent,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ..._optionPool.map((opt) {
            final letter = opt.letter;
            final text = opt.text;
            final isUsed = used.contains(_normalized(letter));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isUsed ? Colors.grey[400] : _accent,
                  ),
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

  Widget _questionCard(ExerciseQuestion q) {
    final num = q.number;
    if (q.answer == kNoAnswerSentinel) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ExamColors.surfaceWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ExamColors.border, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$num.  ',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Expanded(
              child: Text(
                S.of(context).frageNichtInQuelle,
                style: const TextStyle(
                  fontSize: 14,
                  color: ExamColors.inkMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final type = q.type;
    final selected = _selected[num];
    final correct = _showResults && selected != null ? _isCorrect(q) : null;

    Color borderColor = ExamColors.border;
    if (correct != null) borderColor = correct ? _green : _red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ExamColors.surface,
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
                _optionPool.map((o) => o.letter).toList(),
              ),
              _ => _choiceOptions(q),
            },
            if (correct == false) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 14, color: _green),
                  const SizedBox(width: 4),
                  Text(
                    'Richtig: ${q.answer.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _questionHeader(ExerciseQuestion q, bool? correct) {
    final num = q.number;
    final text = q.text;
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: ExamColors.ink,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: head,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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

  Widget _tfButtons(ExerciseQuestion q) {
    final num = q.number;
    final selected = _selected[num];
    final correct = _normalized(q.answer);
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

    return Row(
      children: [button('richtig', 'Richtig'), button('falsch', 'Falsch')],
    );
  }

  // Each option in a matching exercise (Lesen Teil 1/3, Hören Teil 2) names
  // one specific text/person and is meant to be used at most once — once
  // it's picked for one question, it shouldn't be pickable for another.
  bool _letterUsedElsewhere(int currentNum, String letter) {
    final target = _normalized(letter);
    // Lesen Teil 3's "x" (Kein Text passt) legitimately applies to more
    // than one item — never disable it.
    if (target == 'x') return false;
    for (final other in _questions) {
      if (other.type != 'match') continue;
      final otherNum = other.number;
      if (otherNum == currentNum) continue;
      final otherSelected = _selected[otherNum];
      if (otherSelected != null && _normalized(otherSelected) == target) {
        return true;
      }
    }
    return false;
  }

  Widget _letterRows(ExerciseQuestion q, List<String> letters) {
    final num = q.number;
    final selected = _selected[num];
    final correct = _normalized(q.answer);

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
                    child: Builder(
                      builder: (context) {
                        final isSelected =
                            selected != null &&
                            _normalized(selected) == _normalized(l);
                        final usedElsewhere =
                            !isSelected && _letterUsedElsewhere(num, l);
                        return _AnswerButton(
                          label: l,
                          selected: isSelected,
                          showResult: _showResults,
                          isCorrect: _normalized(l) == correct,
                          usedElsewhere: usedElsewhere,
                          navy: _navy,
                          onTap: _showResults || usedElsewhere
                              ? null
                              : () => setState(() => _selected[num] = l),
                        );
                      },
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

  Widget _choiceOptions(ExerciseQuestion q) {
    final num = q.number;
    final options = q.options;
    final correct = _normalized(q.answer);
    final selected = _selected[num];

    return Column(
      children: options.map((opt) {
        final letter = opt.letter;
        final optText = opt.text;
        final isSelected =
            selected != null && _normalized(selected) == _normalized(letter);
        final isCorrect = _normalized(letter) == correct;

        Color bg = ExamColors.surfaceWarm;
        Color fg = ExamColors.ink;
        Color borderColor = ExamColors.border;
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Text(
              '$letter) $optText',
              style: TextStyle(color: fg, fontSize: 14, fontWeight: weight),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── result banner + bottom bar ───────────────────────────────────────────

  Widget _buildResultBanner(S s) {
    final all = _answerableQuestions.length;
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
                s.vonRichtig(correct, all),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                correct == all
                    ? s.ausgezeichnetAllesRichtig
                    : s.schauenSieFalscheAntworten,
                style: TextStyle(
                  fontSize: 13,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(S s) {
    if (_questions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: ExamColors.surface,
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
                label: Text(s.neuVersuchen),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: BorderSide(color: _accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _check,
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
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
          ],
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

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.accent,
  });

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
            color: ExamColors.ink,
          ),
        ),
      ],
    );
  }
}

const _textCardBodyStyle = TextStyle(
  fontSize: 13.5,
  color: ExamColors.ink,
  height: 1.5,
);
const _textCardHeadingStyle = TextStyle(
  fontSize: 13.5,
  color: ExamColors.ink,
  fontWeight: FontWeight.w700,
  height:
      2.0, // extra room above/below — it's a new sub-section, not a run-on sentence
);

/// Renders "**heading**" markers (see prompts.py's HEADINGS rule) as bold
/// spans instead of showing the literal asterisks — a plain Text() had no
/// way to distinguish a Protokoll's "TOP 1 ..." agenda items or a
/// document's own sub-headings from surrounding body prose, even though
/// the source PDF sets them apart visually. A top-level function (not a
/// State method) so it's unit-testable without widget-test scaffolding.
final _headingPattern = RegExp(r'\*\*(.+?)\*\*');

@visibleForTesting
TextSpan buildContentSpan(String content) {
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in _headingPattern.allMatches(content)) {
    if (m.start > last) {
      spans.add(
        TextSpan(
          text: content.substring(last, m.start),
          style: _textCardBodyStyle,
        ),
      );
    }
    spans.add(TextSpan(text: m.group(1), style: _textCardHeadingStyle));
    last = m.end;
  }
  if (last < content.length) {
    spans.add(
      TextSpan(text: content.substring(last), style: _textCardBodyStyle),
    );
  }
  return TextSpan(children: spans);
}

class _TextCard extends StatefulWidget {
  final String title;
  final String content;
  final Color accent;
  final String recordingId;
  final VoiceGenderMetadata voiceMetadata;
  final bool initiallyExpanded;
  final bool showAudioPlayer;

  const _TextCard({
    super.key,
    required this.title,
    required this.content,
    required this.accent,
    required this.recordingId,
    required this.voiceMetadata,
    this.initiallyExpanded = false,
    this.showAudioPlayer = false,
  });

  @override
  State<_TextCard> createState() => _TextCardState();
}

class _TextCardState extends State<_TextCard>
    with AutomaticKeepAliveClientMixin {
  late bool _expanded = widget.initiallyExpanded;

  // ListView virtualizes its children via a SliverList — scrolling a card
  // far enough off-screen disposes its Element/State entirely, so without
  // opting into keep-alive, an expanded card silently collapses back to
  // initiallyExpanded once scrolled back into view.
  @override
  bool get wantKeepAlive => true;

  // "a) Auf ins Abenteuer!" → badge "a", title "Auf ins Abenteuer!"
  (String, String) get _badgeAndTitle {
    final m = RegExp(r'^([a-zA-Zа-яА-Я])\)\s*(.+)$').firstMatch(widget.title);
    if (m != null) return (m.group(1)!, m.group(2)!);
    return ('', widget.title);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final (badge, title) = _badgeAndTitle;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ExamColors.surface,
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
                          color: ExamColors.ink,
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
                  if (widget.showAudioPlayer)
                    DialogueAudioPlayer(
                      text: widget.content,
                      accent: widget.accent,
                      recordingId: widget.recordingId,
                      parsedVoiceGender: widget.voiceMetadata.voiceGender,
                      parsedSpeakerVoiceGenders:
                          widget.voiceMetadata.speakerVoiceGenders,
                      showTextToggle: false,
                      initiallyShowText: true,
                    )
                  else
                    RichText(text: buildContentSpan(widget.content)),
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
  final bool usedElsewhere;

  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.showResult,
    required this.isCorrect,
    required this.navy,
    required this.onTap,
    this.usedElsewhere = false,
  });

  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFD32F2F);

  Color get _bgColor {
    if (usedElsewhere) return ExamColors.progressTrack;
    if (!selected && !(showResult && isCorrect)) return ExamColors.surfaceWarm;
    if (showResult) {
      if (selected && isCorrect) return _green;
      if (selected && !isCorrect) return _red;
      if (!selected && isCorrect) return const Color(0xFFE8F5E9);
    }
    return navy;
  }

  Color get _textColor {
    if (usedElsewhere) return const Color(0xFFBDBDBD);
    if (!selected && !(showResult && isCorrect)) return ExamColors.ink;
    if (showResult) {
      if (selected) return Colors.white;
      if (isCorrect) return _green;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // 48dp is the platform-recommended minimum touch target (was
          // 36dp) — this button is often the entire tappable area, not
          // just a decorative badge inside a larger InkWell.
          height: 48,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : showResult && isCorrect
                  ? _green
                  : ExamColors.border,
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
              decoration: usedElsewhere ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}
