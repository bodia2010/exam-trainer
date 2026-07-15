import 'dart:async';
import 'package:flutter/material.dart';
import '../data/b2_beruf_sprechen_data.dart';
import '../l10n/strings.dart';
import '../models/sprechen.dart';
import '../widgets/favorite_button.dart';

class SprechenExerciseScreen extends StatefulWidget {
  final String exerciseId;
  const SprechenExerciseScreen({super.key, required this.exerciseId});

  @override
  State<SprechenExerciseScreen> createState() => _SprechenExerciseScreenState();
}

class _SprechenExerciseScreenState extends State<SprechenExerciseScreen> {
  static const _accentColor = Color(0xFF6A1B9A);

  late final SprechenExercise _exercise;

  int _secondsLeft = 120;
  bool _running = false;
  bool _finished = false;
  bool _showRedemittel = false;
  bool _showAnswer = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _exercise = b2BerufSprechenExercises.firstWhere(
      (e) => e.id == widget.exerciseId,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startOrPause() {
    if (_finished) return;
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          if (_secondsLeft > 0) _secondsLeft--;
          if (_secondsLeft == 0) {
            t.cancel();
            _finished = true;
            _running = false;
          }
        });
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 120;
      _running = false;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _exercise.topic,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Sprechen · B2 Beruf',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          FavoriteButton(
            favId: '/sprechen/b2-beruf/teil1/${widget.exerciseId}',
            title: _exercise.topic,
            subtitle: 'Sprechen · Teil 1',
            route: '/sprechen/b2-beruf/teil1/${widget.exerciseId}',
            courseId: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskCard(s),
            const SizedBox(height: 16),
            _buildTimerCard(s),
            const SizedBox(height: 16),
            _buildCollapsibleCard(
              label: s.redemittel,
              expanded: _showRedemittel,
              onToggle: () =>
                  setState(() => _showRedemittel = !_showRedemittel),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _exercise.redemittel
                    .map(
                      (phrase) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            phrase,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _buildCollapsibleCard(
              label: s.musterantwort,
              expanded: _showAnswer,
              onToggle: () => setState(() => _showAnswer = !_showAnswer),
              child: Text(
                _exercise.exampleAnswer,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(S s) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, color: _accentColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.aufgabeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _exercise.taskText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(S s) {
    final timerColor = _running ? _accentColor : Colors.grey;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
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
          Text(
            s.redezeit,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _accentColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _timerDisplay,
              style: TextStyle(
                fontSize: 48,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: timerColor,
              ),
            ),
          ),
          if (_finished) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                s.zeitAbgelaufenAusruf,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _finished ? null : _startOrPause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _running
                        ? s.pause
                        : (_secondsLeft < 120 && !_finished)
                        ? s.weiter
                        : s.start,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentColor,
                    side: const BorderSide(color: _accentColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    s.zuruecksetzen,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required String label,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: _accentColor,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ],
      ),
    );
  }
}
