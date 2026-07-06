import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/tts_service.dart';

/// Synthesizes German dialogue/monologue audio (via TtsService) lazily on
/// first tap, caches it, then plays each line back-to-back through a
/// single AudioPlayer — with a seek bar and, once the transcript is
/// revealed, the currently-sounding line/sentence highlighted karaoke-style.
///
/// This widget owns the transcript's rendering (not just the play button):
/// only it knows which of its synthesized lines is currently playing, and
/// _lines is a cleaned-up reconstruction of [text] (de-hyphenated, line
/// wraps rejoined — see TtsService.parseLines) rather than the original
/// raw string, so highlighting needs its own text, not the source string.
class DialogueAudioPlayer extends StatefulWidget {
  final String text;
  final Color accent;

  /// Whether this widget shows its own eye-icon toggle to reveal the
  /// transcript. Set to false when an ancestor (e.g. an ExpansionTile)
  /// already gates visibility, to avoid a redundant second toggle.
  final bool showTextToggle;
  final bool initiallyShowText;

  const DialogueAudioPlayer({
    super.key,
    required this.text,
    required this.accent,
    this.showTextToggle = true,
    this.initiallyShowText = false,
  });

  @override
  State<DialogueAudioPlayer> createState() => _DialogueAudioPlayerState();
}

enum _PlayerState { idle, preparing, playing, paused, error }

class _DialogueAudioPlayerState extends State<DialogueAudioPlayer> {
  static const _gap = Duration(milliseconds: 350);

  final _player = AudioPlayer();
  late final List<DialogueLine> _lines =
      TtsService.instance.parseLines(widget.text);
  late bool _showText = widget.initiallyShowText;
  List<String>? _paths; // resolved local file paths, once ready

  _PlayerState _state = _PlayerState.idle;
  int _prepared = 0;
  int _currentLine = 0;
  String? _error;
  int _playToken = 0; // bumped on stop to cancel an in-flight play chain

  // Progress of the currently playing clip, for the seek bar. Only this
  // one clip's position is tracked — clips are per-line/sentence chunks
  // played back-to-back, not one continuous file.
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration> _durationSub;

  bool get _isActive =>
      _state == _PlayerState.playing || _state == _PlayerState.paused;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _durationSub.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _start({bool forceRegenerate = false}) async {
    if (_lines.isEmpty) return;
    setState(() {
      _state = _PlayerState.preparing;
      _prepared = 0;
      _error = null;
    });

    try {
      final paths = <String>[];
      for (final line in _lines) {
        paths.add(await TtsService.instance
            .ensureAudio(line, forceRegenerate: forceRegenerate));
        if (!mounted) return;
        setState(() => _prepared++);
      }
      _paths = paths;
      _currentLine = 0;
      await _playFrom(0);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _PlayerState.error;
          _error = e.toString();
        });
      }
    }
  }

  /// Stops playback, wipes the cached clips and re-synthesizes everything
  /// from scratch — for when a line came out cut off or garbled.
  Future<void> _regenerate() async {
    _playToken++;
    await _player.stop();
    await TtsService.instance.clearCache(_lines);
    if (!mounted) return;
    await _start(forceRegenerate: true);
  }

  Future<void> _playFrom(int index) async {
    final paths = _paths;
    if (paths == null || index >= paths.length) {
      if (mounted) setState(() => _state = _PlayerState.idle);
      return;
    }
    final token = _playToken;
    setState(() {
      _state = _PlayerState.playing;
      _currentLine = index;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    await _player.play(DeviceFileSource(paths[index]));
    late final StreamSubscription onComplete;
    onComplete = _player.onPlayerComplete.listen((_) async {
      onComplete.cancel();
      if (token != _playToken || !mounted) return;
      await Future.delayed(_gap);
      if (token != _playToken || !mounted) return;
      _playFrom(index + 1);
    });
  }

  void _togglePause() {
    if (_state == _PlayerState.playing) {
      _player.pause();
      setState(() => _state = _PlayerState.paused);
    } else if (_state == _PlayerState.paused) {
      _player.resume();
      setState(() => _state = _PlayerState.playing);
    }
  }

  void _stop() {
    _playToken++;
    _player.stop();
    setState(() {
      _state = _PlayerState.idle;
      _currentLine = 0;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  void _jumpTo(int index) {
    if (!_isActive) return;
    _playFrom(index);
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildControls()),
            if (widget.showTextToggle)
              IconButton(
                onPressed: () => setState(() => _showText = !_showText),
                icon: Icon(
                  _showText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                color: Colors.grey[600],
                tooltip: _showText ? 'Text ausblenden' : 'Text anzeigen',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        if (_showText) ...[
          const SizedBox(height: 8),
          _buildTranscript(),
        ],
      ],
    );
  }

  Widget _buildControls() {
    return switch (_state) {
      _PlayerState.idle => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () => _start(),
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: const Text('Text vorlesen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.accent,
                side: BorderSide(color: widget.accent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _regenerate,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: Colors.grey[600],
              tooltip: 'Audio neu generieren',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      _PlayerState.preparing => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: widget.accent),
            ),
            const SizedBox(width: 10),
            Text('Audio wird generiert… $_prepared/${_lines.length}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
      _PlayerState.playing || _PlayerState.paused => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _togglePause,
                  icon: Icon(
                    _state == _PlayerState.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: widget.accent,
                    size: 32,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_circle_outlined, size: 28),
                  color: Colors.grey[600],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
                Text('${_currentLine + 1}/${_lines.length}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _regenerate,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: Colors.grey[600],
                  tooltip: 'Audio neu generieren',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Row(
              children: [
                Text(_formatTime(_position),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds
                              .clamp(0, _duration.inMilliseconds)
                              .toDouble()
                          : 0,
                      max: _duration.inMilliseconds > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1,
                      activeColor: widget.accent,
                      inactiveColor: widget.accent.withValues(alpha: 0.2),
                      onChanged: _duration.inMilliseconds > 0
                          ? (v) => _player
                              .seek(Duration(milliseconds: v.toInt()))
                          : null,
                    ),
                  ),
                ),
                Text(_formatTime(_duration),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      _PlayerState.error => Row(
          children: [
            Expanded(
              child: Text(_error ?? 'Fehler beim Generieren',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFC62828))),
            ),
            TextButton(
              onPressed: _regenerate,
              child: const Text('Wiederholen'),
            ),
          ],
        ),
    };
  }

  // ─── transcript with karaoke-style highlight ──────────────────────────────

  Widget _buildTranscript() {
    final hasSpeakers = _lines.any((l) => l.speaker.isNotEmpty);
    return hasSpeakers ? _buildDialogueTurns() : _buildMonologueParagraph();
  }

  Widget _buildDialogueTurns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _lines.length; i++)
          _turnTile(i, _lines[i]),
      ],
    );
  }

  Widget _turnTile(int index, DialogueLine line) {
    final active = _isActive && index == _currentLine;
    return GestureDetector(
      onTap: () => _jumpTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? widget.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 13.5, height: 1.5, color: Colors.black87),
            children: [
              if (line.speaker.isNotEmpty)
                TextSpan(
                  text: '${line.speaker}: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: widget.accent),
                ),
              TextSpan(text: line.text),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonologueParagraph() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 13.5, height: 1.6, color: Colors.black87),
        children: [
          for (var i = 0; i < _lines.length; i++) ...[
            TextSpan(
              text: _lines[i].text,
              style: TextStyle(
                backgroundColor: _isActive && i == _currentLine
                    ? widget.accent.withValues(alpha: 0.18)
                    : null,
                fontWeight: _isActive && i == _currentLine
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            if (i < _lines.length - 1) const TextSpan(text: ' '),
          ],
        ],
      ),
    );
  }
}
