import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/tts_service.dart';

/// Button that lazily synthesizes German dialogue/monologue audio (via
/// TtsService) on first tap, caches it, then plays each line back-to-back
/// through a single AudioPlayer. Shows a generation progress state while
/// lines are being synthesized, and play/pause/stop controls afterwards.
class DialogueAudioPlayer extends StatefulWidget {
  final String text;
  final Color accent;
  const DialogueAudioPlayer({
    super.key,
    required this.text,
    required this.accent,
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
  List<String>? _paths; // resolved local file paths, once ready

  _PlayerState _state = _PlayerState.idle;
  int _prepared = 0;
  int _currentLine = 0;
  String? _error;
  int _playToken = 0; // bumped on stop to cancel an in-flight play chain

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) return const SizedBox.shrink();

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
      _PlayerState.playing || _PlayerState.paused => Row(
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
}
