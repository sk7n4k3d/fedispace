import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Individual reel widget with video player, loading indicator, and mute toggle.
class ReelItem extends StatefulWidget {
  final String videoUrl;
  final String previewUrl;
  final bool shouldPlay;
  final VoidCallback? onDoubleTap;

  const ReelItem({
    Key? key,
    required this.videoUrl,
    required this.previewUrl,
    this.shouldPlay = false,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  State<ReelItem> createState() => ReelItemState();
}

class ReelItemState extends State<ReelItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _showPlayIcon = false;

  VideoPlayerController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          if (widget.shouldPlay) {
            _controller.play();
          }
        }
      });
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPlay && !oldWidget.shouldPlay) {
      _controller.play();
    } else if (!widget.shouldPlay && oldWidget.shouldPlay) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void play() {
    if (_isInitialized) _controller.play();
  }

  void pause() {
    if (_isInitialized) _controller.pause();
  }

  void toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _showPlayIcon = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showPlayIcon = false);
      });
    } else {
      _controller.play();
      setState(() => _showPlayIcon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: widget.onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or preview
          if (_isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Stack(
              fit: StackFit.expand,
              children: [
                if (widget.previewUrl.isNotEmpty)
                  Image.network(
                    widget.previewUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.black),
                  )
                else
                  Container(color: Colors.black),
                const Center(
                  child: CircularProgressIndicator(
                    color: CyberpunkTheme.neonCyan,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),

          // Buffering indicator
          if (_isInitialized && _controller.value.isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: CyberpunkTheme.neonCyan,
                strokeWidth: 2,
              ),
            ),

          // Play icon overlay
          if (_showPlayIcon)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),

          // Mute toggle (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: toggleMute,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Progress indicator at bottom
          if (_isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: CyberpunkTheme.neonCyan,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
