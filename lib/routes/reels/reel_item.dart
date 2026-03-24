import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Premium full-screen reel item with video player.
/// Features: loop playback, tap to pause/play, mute toggle,
/// thumbnail preview until loaded, buffering indicator, progress bar.
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

class ReelItemState extends State<ReelItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _showPlayPauseIcon = false;
  bool _isPaused = false;
  bool _showMuteIcon = false;
  bool _hasError = false;

  VideoPlayerController? get controller => _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: const {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 16) FediSpace/0.1.5',
        },
      );
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.shouldPlay) {
          _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null || !_isInitialized) return;
    if (widget.shouldPlay && !oldWidget.shouldPlay) {
      _controller!.play();
      _isPaused = false;
    } else if (!widget.shouldPlay && oldWidget.shouldPlay) {
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void play() {
    if (_isInitialized) {
      _controller?.play();
      _isPaused = false;
    }
  }

  void pause() {
    if (_isInitialized) {
      _controller?.pause();
      _isPaused = true;
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _isPaused = true;
      _showPauseIcon(Icons.pause_rounded);
    } else {
      _controller!.play();
      _isPaused = false;
      _showPauseIcon(Icons.play_arrow_rounded);
    }
  }

  void _showPauseIcon(IconData icon) {
    setState(() {
      _showPlayPauseIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showPlayPauseIcon = false);
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      _showMuteIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showMuteIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: _toggleMute,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail (shown until video loads)
            if (!_isInitialized && widget.previewUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.previewUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black),
                errorWidget: (_, __, ___) => Container(color: Colors.black),
              ),

            // Video
            if (_isInitialized && _controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // Loading indicator (before init)
            if (!_isInitialized && !_hasError)
              const Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: CyberpunkTheme.neonCyan,
                    strokeWidth: 2,
                  ),
                ),
              ),

            // Buffering indicator
            if (_isInitialized &&
                _controller != null &&
                _controller!.value.isBuffering)
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    color: CyberpunkTheme.neonCyan,
                    strokeWidth: 2,
                  ),
                ),
              ),

            // Error state
            if (_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: CyberpunkTheme.textTertiary, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Video unavailable',
                      style: TextStyle(
                        color: CyberpunkTheme.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Play/Pause icon overlay
            if (_showPlayPauseIcon)
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          _isPaused
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Mute indicator overlay
            if (_showMuteIcon)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 0,
                right: 0,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isMuted ? 'Muted' : 'Sound on',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Progress bar at very bottom
            if (_isInitialized && _controller != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 2,
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: CyberpunkTheme.neonCyan,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
