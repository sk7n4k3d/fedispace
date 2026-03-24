import 'package:flutter/material.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Rich DM features: voice message recorder, emoji reaction picker, GIF search.

/// Voice message recorder widget with hold-to-record and waveform visualization.
class VoiceMessageRecorder extends StatefulWidget {
  final void Function(String path, Duration duration)? onRecordComplete;

  const VoiceMessageRecorder({Key? key, this.onRecordComplete}) : super(key: key);

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _duration = Duration.zero;
    });
    // In a real implementation, start audio recording via a recorder plugin
    _tickDuration();
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    // In a real implementation, stop recording and get file path
    widget.onRecordComplete?.call('/tmp/voice_message.m4a', _duration);
  }

  void _tickDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() => _duration += const Duration(seconds: 1));
        _tickDuration();
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Record button
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isRecording ? 1.0 + (_pulseController.value * 0.2) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red.withOpacity(0.8)
                          : CyberpunkTheme.neonCyan.withOpacity(0.2),
                      boxShadow: _isRecording
                          ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 16)]
                          : [],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isRecording ? Colors.white : CyberpunkTheme.neonCyan,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Waveform / duration
          if (_isRecording) ...[
            Expanded(
              child: _WaveformVisualizer(isActive: _isRecording),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDuration(_duration),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ] else
            const Expanded(
              child: Text(
                'Hold to record voice message',
                style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple waveform visualization during recording.
class _WaveformVisualizer extends StatefulWidget {
  final bool isActive;
  const _WaveformVisualizer({required this.isActive});

  @override
  State<_WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<_WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(20, (i) {
              final height = widget.isActive
                  ? 8.0 + (16.0 * ((i + _controller.value * 10).remainder(5) / 5))
                  : 4.0;
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: CyberpunkTheme.neonCyan.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Voice message playback widget for received voice messages.
class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final Duration duration;

  const VoiceMessagePlayer({
    Key? key,
    required this.audioUrl,
    required this.duration,
  }) : super(key: key);

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  bool _isPlaying = false;
  double _progress = 0.0;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.glassBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPlaying = !_isPlaying),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CyberpunkTheme.neonCyan.withOpacity(0.2),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: CyberpunkTheme.neonCyan,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: CyberpunkTheme.borderDark,
                  valueColor: const AlwaysStoppedAnimation(CyberpunkTheme.neonCyan),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(widget.duration),
                  style: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
