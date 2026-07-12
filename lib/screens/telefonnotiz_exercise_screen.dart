import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../services/course_storage.dart';
import '../widgets/dialogue_audio_player.dart';
import '../widgets/favorite_button.dart';

class TelefonnotizExerciseScreen extends StatefulWidget {
  final String courseId;
  final int index;
  const TelefonnotizExerciseScreen({
    super.key,
    required this.courseId,
    required this.index,
  });

  @override
  State<TelefonnotizExerciseScreen> createState() => _TelefonnotizExerciseScreenState();
}

class _TelefonnotizExerciseScreenState extends State<TelefonnotizExerciseScreen> {
  Map<String, dynamic>? _variant;
  int _versionIndex = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await CourseStorage.instance.loadAll();
    final course = all.where((c) => c.id == widget.courseId).firstOrNull;
    if (course != null && mounted) {
      final variants = course.sections['telefonnotiz'] ?? [];
      if (widget.index < variants.length) {
        setState(() => _variant = variants[widget.index] as Map<String, dynamic>);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final v = _variant;
    if (v == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final varNum = v['variant_number'] ?? (widget.index + 1);
    final topic = v['topic'] as String? ?? '';
    final versions = (v['versions'] as List? ?? []).cast<Map<String, dynamic>>();
    final version = versions.isNotEmpty ? versions[_versionIndex] : <String, dynamic>{};
    final audioUrl = version['audio_url'] as String?;
    final monologue = version['monologue'] as String? ?? '';
    final answer = version['answer'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        title: Text(s.telefonnotizVariante(varNum)),
        elevation: 0,
        actions: [
          FavoriteButton(
            favId: '/course/${widget.courseId}/telefonnotiz/${widget.index}',
            title: s.telefonnotizVariante(varNum),
            subtitle: 'Hören + Schreiben',
            route: '/course/${widget.courseId}/telefonnotiz/${widget.index}',
            courseId: widget.courseId,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (topic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(topic,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF00838F))),
            ),
          if (versions.length > 1) _versionTabs(versions, s),
          const SizedBox(height: 12),
          if (audioUrl != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00838F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () =>
                  launchUrl(Uri.parse(audioUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(s.aufnahmeAnhoeren),
            ),
          const SizedBox(height: 12),
          if (monologue.isNotEmpty) ...[
            DialogueAudioPlayer(
                text: monologue, accent: const Color(0xFF00838F)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          _answerCard(answer, s),
        ],
      ),
    );
  }

  Widget _versionTabs(List<Map<String, dynamic>> versions, S s) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: versions.asMap().entries.map((e) {
          final label = (e.value['label'] as String?)?.isNotEmpty == true
              ? e.value['label'] as String
              : s.variante(e.key + 1);
          final selected = e.key == _versionIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              selectedColor: const Color(0xFF00838F),
              labelStyle: TextStyle(color: selected ? Colors.white : null),
              onSelected: (_) => setState(() {
                _versionIndex = e.key;
                _showAnswer = false;
              }),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _answerCard(Map<String, dynamic> answer, S s) {
    final fields = [
      (s.anrufTyp, answer['call_type']),
      (s.name, answer['name']),
      (s.telefon, answer['telefonnummer']),
    ];
    final bullets = (answer['weitere_informationen'] as List? ?? []).cast<String>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Telefonnotiz',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _showAnswer = !_showAnswer),
                  icon: Icon(
                      _showAnswer
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18),
                  label: Text(_showAnswer ? s.ausblenden : s.antworten,
                      style: const TextStyle(color: Color(0xFF00838F))),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF00838F)),
                ),
              ],
            ),
            if (_showAnswer) ...[
              const Divider(),
              ...fields.map((f) => _field(f.$1, f.$2?.toString() ?? '')),
              if (bullets.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.weitereInformationen,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                ...bullets.map((b) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFF00838F))),
                          Expanded(child: Text(b)),
                        ],
                      ),
                    )),
                const SizedBox(height: 6),
              ],
              _field(s.zuErledigen, answer['zu_erledigen']?.toString() ?? '',
                  boldLabel: true),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(s.antwortNachAnhoerenHint,
                    style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value, {bool boldLabel = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    // The source answer key prints "Zu erledigen: ..." as one bold
    // sentence, not a label column next to a value column — match that
    // instead of reusing the two-column layout the other fields use.
    if (boldLabel) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            children: [
              TextSpan(text: '$label: '),
              TextSpan(text: value),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Color(0xFF757575), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
