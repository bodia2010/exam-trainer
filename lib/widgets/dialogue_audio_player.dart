import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../services/tts_service.dart';

/// Minimal seam over `package:audioplayers`' `AudioPlayer` — the exact
/// handful of members [DialogueAudioPlayer] actually calls, nothing more.
/// Production code always uses [_RealAudioPlayerAdapter] (the default);
/// widget tests can implement this directly to inject a fake that avoids
/// `audioplayers`' platform channels entirely, which aren't mocked in
/// plain `flutter test` (confirmed: even `AudioPlayer().stop()` throws
/// `MissingPluginException` with no platform implementation registered).
/// This is deliberately NOT a general wrapper around the whole package —
/// just enough surface to make play()/pause()/error-path behavior
/// testable without an architectural rewrite.
abstract class AudioPlayerAdapter {
  Stream<Duration> get onPositionChanged;
  Stream<Duration> get onDurationChanged;
  Stream<void> get onPlayerComplete;
  Future<void> play(Source source);
  Future<void> setPlaybackRate(double rate);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

class _RealAudioPlayerAdapter implements AudioPlayerAdapter {
  _RealAudioPlayerAdapter() : _player = AudioPlayer();
  final AudioPlayer _player;

  @override
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  @override
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  @override
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;
  @override
  Future<void> play(Source source) => _player.play(source);
  @override
  Future<void> setPlaybackRate(double rate) => _player.setPlaybackRate(rate);
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> dispose() => _player.dispose();
}

/// Synthesizes German dialogue/monologue audio (via TtsService) lazily on
/// first tap, caches it, then plays each line back-to-back through a
/// single AudioPlayer — with a seek bar, playback speed control, and,
/// once the transcript is revealed, the currently-sounding line/sentence
/// highlighted karaoke-style.
///
/// This widget owns the transcript's rendering (not just the play button):
/// only it knows which of its synthesized lines is currently playing, and
/// _lines is a cleaned-up reconstruction of [text] (de-hyphenated, line
/// wraps rejoined — see TtsService.parseLines) rather than the original
/// raw string, so highlighting needs its own text, not the source string.
class DialogueAudioPlayer extends StatefulWidget {
  final String text;
  final Color accent;

  /// Whether this widget shows its own "Transkript anzeigen" toggle. Set
  /// to false when an ancestor (e.g. an ExpansionTile) already gates
  /// visibility, to avoid a redundant second toggle.
  final bool showTextToggle;
  final bool initiallyShowText;

  /// Test seam: `null` (the default, untouched in production) means "use
  /// a real `AudioPlayer` via [_RealAudioPlayerAdapter]". See
  /// [AudioPlayerAdapter]'s doc for why this exists.
  @visibleForTesting
  final AudioPlayerAdapter Function()? debugPlayerFactory;

  const DialogueAudioPlayer({
    super.key,
    required this.text,
    required this.accent,
    this.showTextToggle = true,
    this.initiallyShowText = false,
    this.debugPlayerFactory,
  });

  @override
  State<DialogueAudioPlayer> createState() => _DialogueAudioPlayerState();
}

enum _PlayerState { idle, preparing, playing, paused, error }

class _DialogueAudioPlayerState extends State<DialogueAudioPlayer> {
  static const _gap = Duration(milliseconds: 350);
  static const _speeds = [0.75, 1.0, 1.25, 1.5];

  late final AudioPlayerAdapter _player =
      widget.debugPlayerFactory?.call() ?? _RealAudioPlayerAdapter();
  late final List<DialogueLine> _lines = TtsService.instance.parseLines(
    widget.text,
  );
  late bool _showText = widget.initiallyShowText;
  List<String>? _paths; // resolved local file paths, once ready

  _PlayerState _state = _PlayerState.idle;
  int _prepared = 0;
  int _currentLine = 0;
  // Bumped whenever a new prepare/play/stop/dispose operation supersedes
  // whatever async chain is currently in flight (_start's ensureAudio
  // loop, _playFrom's play-and-await-completion chain). Every await
  // boundary that leads to a setState, playback call, or state mutation
  // re-checks its captured token against this field first — a stale
  // operation that resumes after being superseded must not touch UI,
  // start playback, or overwrite the newer operation's state.
  int _opToken = 0;
  double _playbackRate = 1.0;

  // Progress of the currently playing clip, for the seek bar. Only this
  // one clip's position is tracked — clips are per-line/sentence chunks
  // played back-to-back, not one continuous file.
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration> _durationSub;
  StreamSubscription<void>? _onCompleteSub;

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
    // Invalidate any in-flight _start/_playFrom chain so a resumed await
    // past this point sees a stale token and bails out before touching
    // state or the (about-to-be-disposed) player.
    _opToken++;
    _positionSub.cancel();
    _durationSub.cancel();
    _onCompleteSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _speedLabel => _playbackRate == _playbackRate.truncateToDouble()
      ? '${_playbackRate.toInt()}×'
      : '$_playbackRate×';

  Future<void> _cycleSpeed() async {
    final next = _speeds[(_speeds.indexOf(_playbackRate) + 1) % _speeds.length];
    final token = _opToken;
    try {
      await _player.setPlaybackRate(next);
    } catch (_) {
      if (!mounted || token != _opToken) return;
      setState(() => _state = _PlayerState.error);
      return;
    }
    if (!mounted || token != _opToken) return;
    setState(() => _playbackRate = next);
  }

  Future<void> _start({bool forceRegenerate = false}) async {
    if (_lines.isEmpty) return;
    // Guards against a stray double-tap starting a second overlapping
    // prepare loop; _regenerate() has its own explicit guard for
    // interrupting a running one deliberately.
    if (_state == _PlayerState.preparing) return;
    final token = ++_opToken;
    setState(() {
      _state = _PlayerState.preparing;
      _prepared = 0;
    });

    try {
      final paths = <String>[];
      for (final line in _lines) {
        final path = await TtsService.instance.ensureAudio(
          line,
          forceRegenerate: forceRegenerate,
        );
        if (!mounted || token != _opToken) return;
        paths.add(path);
        setState(() => _prepared++);
      }
      if (!mounted || token != _opToken) return;
      _paths = paths;
      _currentLine = 0;
      await _playFrom(0, token: token);
    } catch (e) {
      // Deliberately not shown to the user — TtsService's failures can
      // carry a raw backend response body (see CR-11's ApiException
      // elsewhere), and _buildBar() always shows the generic
      // s.fehlerBeimGenerieren message instead.
      if (mounted && token == _opToken) {
        setState(() {
          _state = _PlayerState.error;
        });
      }
    }
  }

  /// Stops playback, wipes the cached clips and re-synthesizes everything
  /// from scratch — for when a line came out cut off or garbled. Blocked
  /// while a prepare is already running (initial _start() or a previous
  /// regenerate) so two overlapping prepare operations never race the
  /// same underlying TtsService/cache state; the refresh button is also
  /// disabled in the UI during preparing (see _buildBar).
  Future<void> _regenerate() async {
    if (_state == _PlayerState.preparing) return;
    final token = ++_opToken;
    try {
      await _player.stop();
    } catch (_) {
      // Not fatal to the regenerate flow — a stop() failure (e.g. the
      // player was never actually playing) doesn't stop us from clearing
      // the cache and starting a fresh attempt regardless.
    }
    if (!mounted || token != _opToken) return;
    await TtsService.instance.clearCache(_lines);
    if (!mounted || token != _opToken) return;
    await _start(forceRegenerate: true);
  }

  /// Plays the clip at [index], advancing to the next on completion.
  ///
  /// [_player.play]/[_player.setPlaybackRate] failing (missing/corrupt
  /// file, decoder rejection, a cache clip evicted out from under us —
  /// see TtsService's LRU eviction — or any other platform error) used to
  /// be silently swallowed after `_state` was already optimistically set
  /// to `playing`, leaving the widget showing a live "playing" bar with
  /// no audio and no way out. Both calls are now covered by the same
  /// try/catch: a failure while this operation is still current
  /// transitions to the existing generic error UI instead; a failure
  /// after the operation has been superseded (dispose, a fresh
  /// `_start`/`_regenerate`) is silently dropped, matching every other
  /// await boundary in this class.
  Future<void> _playFrom(int index, {required int token}) async {
    if (!mounted || token != _opToken) return;
    final paths = _paths;
    if (paths == null || index >= paths.length) {
      setState(() => _state = _PlayerState.idle);
      return;
    }
    // Clear any previous line's completion listener before starting this
    // one — whether this attempt succeeds or fails below, a stale
    // listener from an earlier line must never fire and advance playback
    // again.
    _onCompleteSub?.cancel();
    _onCompleteSub = null;
    setState(() {
      _state = _PlayerState.playing;
      _currentLine = index;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    try {
      await _player.play(DeviceFileSource(paths[index]));
      if (!mounted || token != _opToken) return;
      await _player.setPlaybackRate(_playbackRate);
    } catch (_) {
      // Deliberately not shown to the user — see _start's catch for why
      // (TtsService/platform errors can carry a raw path or backend
      // response); _buildBar()'s error branch always shows the generic
      // s.fehlerBeimGenerieren message instead.
      if (!mounted || token != _opToken) return;
      setState(() => _state = _PlayerState.error);
      return;
    }
    if (!mounted || token != _opToken) return;
    // The stale-listener cancel at the top of this function already
    // guarantees only one completion listener is ever registered at a
    // time — just attach this line's.
    _onCompleteSub = _player.onPlayerComplete.listen((_) async {
      _onCompleteSub?.cancel();
      _onCompleteSub = null;
      if (token != _opToken || !mounted) return;
      await Future.delayed(_gap);
      if (token != _opToken || !mounted) return;
      _playFrom(index + 1, token: token);
    });
  }

  /// pause()/resume() are fire-and-forget from the caller's perspective
  /// (this is a synchronous `onTap` handler) — `.catchError` keeps a
  /// platform failure from becoming an unhandled async exception instead
  /// of silently discarding it, and folds it into the same generic error
  /// UI the rest of the class already uses. Guarded by the op token so a
  /// failure reported after this operation has already been superseded
  /// (stop, a fresh regenerate, dispose) doesn't overwrite newer state.
  void _togglePause() {
    final token = _opToken;
    if (_state == _PlayerState.playing) {
      setState(() => _state = _PlayerState.paused);
      _player.pause().catchError((_) {
        if (!mounted || token != _opToken) return;
        setState(() => _state = _PlayerState.error);
      });
    } else if (_state == _PlayerState.paused) {
      setState(() => _state = _PlayerState.playing);
      _player.resume().catchError((_) {
        if (!mounted || token != _opToken) return;
        setState(() => _state = _PlayerState.error);
      });
    }
  }

  void _stop() {
    _opToken++; // invalidate any in-flight prepare/play chain
    _onCompleteSub?.cancel();
    _onCompleteSub = null;
    // A stop() failure here isn't actionable — the UI already reflects
    // "stopped" below regardless — but must not become an unhandled
    // async exception.
    _player.stop().catchError((_) {});
    setState(() {
      _state = _PlayerState.idle;
      _currentLine = 0;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  void _jumpTo(int index) {
    if (!_isActive) return;
    _playFrom(index, token: _opToken);
  }

  /// A seek failure is cosmetic (the slider drag just doesn't move
  /// playback) — not worth tearing down otherwise-fine active playback
  /// over, but still must not become an unhandled async exception.
  void _seek(Duration position) {
    _player.seek(position).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBar(),
        if (widget.showTextToggle) ...[
          const SizedBox(height: 10),
          _buildTranscriptToggle(),
        ],
        if (_showText) ...[const SizedBox(height: 8), _buildTranscript()],
      ],
    );
  }

  Widget _buildTranscriptToggle() {
    final s = S.of(context);
    final label = _lines.any((l) => l.speaker.isNotEmpty)
        ? s.textDialog
        : s.textAufnahme;
    return Semantics(
      button: true,
      label: label,
      toggled: _showText,
      // The visible Text below already renders this same label, so
      // without this the merged SemanticsNode would announce it twice
      // (Flutter joins merged labels with a newline).
      excludeSemantics: true,
      child: Material(
        color: widget.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _showText = !_showText),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.article_outlined, color: widget.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.accent,
                    ),
                  ),
                ),
                Icon(
                  _showText
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: widget.accent,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── colored audio bar (mirrors deutch-lernen's _AudioBar) ────────────────

  Widget _buildBar() {
    final s = S.of(context);
    if (_state == _PlayerState.error) {
      return Row(
        children: [
          Expanded(
            child: Text(
              s.fehlerBeimGenerieren,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC62828)),
            ),
          ),
          TextButton(onPressed: _regenerate, child: Text(s.wiederholenAction)),
        ],
      );
    }

    final active = _isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? widget.accent : widget.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _leadingIcon(active),
              const SizedBox(width: 8),
              Expanded(child: _label(active)),
              if (active) ...[
                GestureDetector(
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _speedLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(_position)} / ${_formatTime(_duration)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_circle_outlined, size: 22),
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                // Disabled while preparing so a tap can't start a second,
                // overlapping regenerate against the same in-flight
                // prepare operation (see _regenerate's own guard too).
                onPressed: _state == _PlayerState.preparing
                    ? null
                    : _regenerate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: active ? Colors.white70 : Colors.grey[600],
                tooltip: s.audioNeuGenerieren,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (active) ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
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
                onChanged: _duration.inMilliseconds > 0
                    ? (v) => _seek(Duration(milliseconds: v.toInt()))
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _leadingIcon(bool active) {
    if (_state == _PlayerState.preparing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent),
      );
    }
    final s = S.of(context);
    final playing = _state == _PlayerState.playing;
    final label = switch (_state) {
      _PlayerState.playing => s.pausieren,
      _PlayerState.paused => s.weiterhoeren,
      _ => s.dialogAnhoeren,
    };
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: _state == _PlayerState.idle ? () => _start() : _togglePause,
        child: Icon(
          playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
          color: active ? Colors.white : widget.accent,
          size: 28,
        ),
      ),
    );
  }

  Widget _label(bool active) {
    final s = S.of(context);
    final text = switch (_state) {
      _PlayerState.preparing => s.audioWirdGeneriert(_prepared, _lines.length),
      _PlayerState.playing => s.pausieren,
      _PlayerState.paused => s.weiterhoeren,
      _ => s.dialogAnhoeren,
    };
    // liveRegion announces the play/pause/preparing transition to screen
    // readers without the user needing to re-focus this label manually.
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : widget.accent,
        ),
      ),
    );
  }

  // ─── transcript with karaoke-style highlight ──────────────────────────────

  Widget _buildTranscript() {
    final hasSpeakers = _lines.any((l) => l.speaker.isNotEmpty);
    return hasSpeakers ? _buildDialogueTurns() : _buildMonologueParagraph();
  }

  Widget _buildDialogueTurns() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.accent.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _lines.length; i++) _turnTile(i, _lines[i]),
        ],
      ),
    );
  }

  Widget _turnTile(int index, DialogueLine line) {
    final active = _isActive && index == _currentLine;
    return GestureDetector(
      onTap: () => _jumpTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? widget.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: active
              ? Border.all(color: widget.accent.withValues(alpha: 0.4))
              : null,
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: active ? Colors.black87 : const Color(0xFF555555),
            ),
            children: [
              if (line.speaker.isNotEmpty)
                TextSpan(
                  text: '${line.speaker}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.accent,
                  ),
                ),
              TextSpan(text: line.text),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonologueParagraph() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.accent.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.6,
            color: Colors.black87,
          ),
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
      ),
    );
  }
}
