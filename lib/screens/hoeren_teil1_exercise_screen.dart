import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/exercises/hoeren_teil1_variant.dart';
import '../models/voice_gender.dart';
import '../services/course_storage.dart';
import '../ui/features/exercise/variant_loader.dart';
import '../widgets/dialogue_audio_player.dart';
import '../widgets/favorite_button.dart';
import '../widgets/course_load_state.dart';

class HoerenTeil1ExerciseScreen extends StatefulWidget {
  final String courseId;
  final int index;
  final CourseLoader? courseLoader;
  const HoerenTeil1ExerciseScreen({
    super.key,
    required this.courseId,
    required this.index,
    this.courseLoader,
  });

  @override
  State<HoerenTeil1ExerciseScreen> createState() =>
      _HoerenTeil1ExerciseScreenState();
}

class _HoerenTeil1ExerciseScreenState extends State<HoerenTeil1ExerciseScreen> {
  static const _accent = Color(0xFF00838F);

  HoerenTeil1Variant? _variant;
  final _loadGuard = VariantLoadGuard();
  final Map<int, bool?> _rfAnswers = {};
  final Map<int, String?> _mcAnswers = {};
  bool _submitted = false;
  bool _loading = true;
  CourseLoadFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HoerenTeil1ExerciseScreen oldWidget) {
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
      _rfAnswers.clear();
      _mcAnswers.clear();
      _submitted = false;
      _loading = true;
      _failure = null;
    });
    final result = await loadVariant<HoerenTeil1Variant>(
      courseLoader: widget.courseLoader ?? CourseStorage.instance.loadAll,
      courseId: widget.courseId,
      sectionType: 'hoeren_teil1',
      index: widget.index,
      fromJson: (json) =>
          HoerenTeil1Variant.fromJson(json, variantIndex: widget.index),
    );
    if (!mounted || !_loadGuard.isCurrent(generation)) return;
    setState(() {
      _variant = result.variant;
      _failure = result.failure;
      _loading = false;
    });
  }

  List<QuestionPair> get _pairs => _variant?.questionPairs ?? const [];

  int get _totalQuestions => _pairs.fold(0, (sum, pair) {
    var n = 0;
    if (pair.richtigFalsch != null) n++;
    if (pair.multipleChoice != null) n++;
    return sum + n;
  });

  bool get _allAnswered {
    for (final pair in _pairs) {
      final rf = pair.richtigFalsch;
      final mc = pair.multipleChoice;
      if (rf != null && !_rfAnswers.containsKey(rf.number)) {
        return false;
      }
      if (mc != null && !_mcAnswers.containsKey(mc.number)) {
        return false;
      }
    }
    return true;
  }

  int get _correctCount {
    var correct = 0;
    for (final pair in _pairs) {
      final rf = pair.richtigFalsch;
      final mc = pair.multipleChoice;
      if (rf != null && _rfAnswers[rf.number] == rf.answer) {
        correct++;
      }
      if (mc != null && _mcAnswers[mc.number] == mc.correctLetter) {
        correct++;
      }
    }
    return correct;
  }

  void _submit() {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).bitteAlleAufgabenBeantworten),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _submitted = true);
  }

  void _reset() {
    setState(() {
      _rfAnswers.clear();
      _mcAnswers.clear();
      _submitted = false;
    });
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
    final version = v.version;

    return Scaffold(
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
            const Text(
              'Hören — Teil 1',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          FavoriteButton(
            favId: '/course/${widget.courseId}/hoeren_teil1/${widget.index}',
            title: version.isEmpty
                ? s.variante(varNum)
                : s.varianteMitVersion(varNum, version),
            subtitle: 'Hören — Teil 1',
            route: '/course/${widget.courseId}/hoeren_teil1/${widget.index}',
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
            for (var i = 0; i < _pairs.length; i++) ...[
              _buildPairCard(_pairs[i], s),
              const SizedBox(height: 16),
            ],
            if (_submitted) _buildResult(s),
            const SizedBox(height: 16),
            _buildActions(s),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPairCard(QuestionPair pair, S s) {
    final rf = pair.richtigFalsch;
    final mc = pair.multipleChoice;
    final dialogue = pair.dialogue;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dialogue.isNotEmpty) ...[
            DialogueAudioPlayer(
              text: dialogue,
              accent: _accent,
              recordingId: scopedVoiceRecordingId(
                widget.courseId,
                pair.recordingId,
              ),
              parsedVoiceGender: pair.voiceGender,
              parsedSpeakerVoiceGenders: pair.voiceMetadata.speakerVoiceGenders,
            ),
            const SizedBox(height: 14),
          ],
          if (rf != null) ...[
            _buildRichtigFalsch(rf, s),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 14),
          ],
          if (mc != null) _buildMultipleChoice(mc, s),
        ],
      ),
    );
  }

  Widget _buildRichtigFalsch(RichtigFalschQuestion rf, S s) {
    final num = rf.number;
    final statement = rf.statement;
    final correct = rf.answer;
    final selected = _rfAnswers[num];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardLabel(label: s.aufgabeNummer(num)),
        const SizedBox(height: 6),
        Text(
          statement,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _rfButton(num, true, 'Richtig', correct, selected),
            const SizedBox(width: 10),
            _rfButton(num, false, 'Falsch', correct, selected),
          ],
        ),
      ],
    );
  }

  Widget _rfButton(
    int num,
    bool value,
    String label,
    bool? correct,
    bool? selected,
  ) {
    Color bg = Colors.white;
    Color border = Colors.grey.shade300;
    Color fg = Colors.black87;

    if (_submitted) {
      if (value == correct) {
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFF2E7D32);
        fg = const Color(0xFF2E7D32);
      } else if (selected == value) {
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFC62828);
        fg = const Color(0xFFC62828);
      }
    } else if (selected == value) {
      bg = const Color(0xFFE0F7FA);
      border = _accent;
      fg = _accent;
    }

    return Expanded(
      child: GestureDetector(
        onTap: _submitted
            ? null
            : () => setState(() => _rfAnswers[num] = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoice(MultipleChoiceQuestion mc, S s) {
    final num = mc.number;
    final stem = mc.stem;
    final options = mc.options;
    final correct = mc.correctLetter;
    final selected = _mcAnswers[num];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardLabel(label: s.aufgabeNummer(num)),
        const SizedBox(height: 6),
        Text(
          stem,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        for (final opt in options) ...[
          _mcOption(
            num: num,
            letter: opt.letter,
            text: opt.text,
            isSelected: selected == opt.letter,
            isCorrect: opt.letter == correct,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _mcOption({
    required int num,
    required String letter,
    required String text,
    required bool isSelected,
    required bool isCorrect,
  }) {
    Color bg = Colors.white;
    Color border = Colors.grey.shade200;
    Color letterBg = Colors.grey.shade100;
    Color letterColor = Colors.black54;
    Color textColor = Colors.black87;

    if (_submitted) {
      if (isCorrect) {
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFF2E7D32);
        letterBg = const Color(0xFF2E7D32);
        letterColor = Colors.white;
        textColor = const Color(0xFF2E7D32);
      } else if (isSelected) {
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFC62828);
        letterBg = const Color(0xFFC62828);
        letterColor = Colors.white;
        textColor = const Color(0xFFC62828);
      }
    } else if (isSelected) {
      bg = const Color(0xFFE0F7FA);
      border = _accent;
      letterBg = _accent;
      letterColor = Colors.white;
      textColor = const Color(0xFF005662);
    }

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !_submitted,
      label: '$letter. $text',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _submitted
            ? null
            : () => setState(() => _mcAnswers[num] = letter),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: letterBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: letterColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult(S s) {
    final total = _totalQuestions;
    final correct = _correctCount;
    final ratio = total == 0 ? 0.0 : correct / total;
    final color = ratio >= 0.8
        ? const Color(0xFF2E7D32)
        : ratio >= 0.5
        ? const Color(0xFFE65100)
        : const Color(0xFFC62828);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            correct == total ? Icons.check_circle : Icons.info_outline,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              s.vonRichtig(correct, total),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(S s) {
    if (!_submitted) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _submit,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => setState(() => _submitted = true),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(s.antworten),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _reset,
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          side: const BorderSide(color: _accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          s.neuVersuchen,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

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
      child: child,
    );
  }
}

class _CardLabel extends StatelessWidget {
  final String label;
  const _CardLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
        letterSpacing: 0.6,
      ),
    );
  }
}
