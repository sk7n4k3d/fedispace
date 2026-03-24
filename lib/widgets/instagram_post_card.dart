import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/utils/social_actions.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:fedispace/widgets/simple_video_player.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modern post card with cyberpunk accents
class InstagramPostCard extends StatefulWidget {
  final Status status;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final VoidCallback? onProfileTap;

  const InstagramPostCard({
    Key? key,
    required this.status,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
    this.onProfileTap,
  }) : super(key: key);

  @override
  State<InstagramPostCard> createState() => _InstagramPostCardState();
}

class _InstagramPostCardState extends State<InstagramPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  
  late bool _isFavorited;
  late int _favouritesCount;
  late bool _isBookmarked;

  // Translation state
  String? _translatedContent;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.status.favorited;
    _favouritesCount = widget.status.favourites_count;
    _isBookmarked = widget.status.reblogged;

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeOut,
      ),
    );

  }
  
  @override
  void didUpdateWidget(InstagramPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
       _isFavorited = widget.status.favorited;
       _favouritesCount = widget.status.favourites_count;
       _isBookmarked = widget.status.reblogged;
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    if (!_isFavorited) {
      _likeAnimationController.forward(from: 0.0);
      widget.onLike?.call();
      setState(() {
         _isFavorited = true;
         _favouritesCount++;
      });
    } else {
      // Still show heart animation even if already liked
      _likeAnimationController.forward(from: 0.0);
    }
  }

  void _handleTap() {
    Navigator.pushNamed(
      context,
      '/statusDetail',
      arguments: {
        'statusId': widget.status.id,
      },
    );
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageView(imageUrl: imageUrl, heroTag: 'post_image_${widget.status.id}');
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _translateContent() async {
    if (_isTranslating) return;
    
    // Toggle off if already translated
    if (_translatedContent != null) {
      setState(() => _translatedContent = null);
      return;
    }

    setState(() => _isTranslating = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('translate_provider') ?? 'libretranslate';
      final targetLang = prefs.getString('translate_target_lang') ?? 'en';

      // Strip HTML tags for translation
      final plainText = widget.status.content
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .trim();

      if (plainText.isEmpty) {
        setState(() => _isTranslating = false);
        return;
      }

      String? translated;

      if (provider == 'openai') {
        // ── OpenAI translation ──
        final endpoint = prefs.getString('openai_translate_endpoint') ?? 'https://api.openai.com/v1/chat/completions';
        // SECURITY: Read API keys from encrypted secure storage
        const secureStorage = FlutterSecureStorage();
        final apiKey = await secureStorage.read(key: 'openai_translate_api_key') ?? '';
        if (apiKey.isEmpty) {
          setState(() => _isTranslating = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('OpenAI API key not set. Go to Settings → Translation.'), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating),
            );
          }
          return;
        }

        // Map lang code to full name for better LLM understanding
        const langNames = {
          'en': 'English', 'fr': 'French', 'es': 'Spanish', 'de': 'German',
          'it': 'Italian', 'pt': 'Portuguese', 'nl': 'Dutch', 'ru': 'Russian',
          'zh': 'Chinese', 'ja': 'Japanese', 'ko': 'Korean', 'ar': 'Arabic',
          'hi': 'Hindi', 'tr': 'Turkish', 'pl': 'Polish', 'sv': 'Swedish',
          'da': 'Danish', 'fi': 'Finnish', 'no': 'Norwegian', 'uk': 'Ukrainian',
        };
        final langName = langNames[targetLang] ?? targetLang;

        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'system', 'content': 'You are a translator. Translate the following text to $langName. Return ONLY the translated text, nothing else.'},
              {'role': 'user', 'content': plainText},
            ],
            'max_tokens': 1000,
            'temperature': 0.3,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          translated = data['choices']?[0]?['message']?['content']?.toString().trim();
        } else {
          String errMsg = 'OpenAI translation failed (${response.statusCode})';
          try {
            final errData = jsonDecode(response.body);
            errMsg = errData['error']?['message'] ?? errMsg;
          } catch (_) {}
          throw Exception(errMsg);
        }
      } else {
        // ── LibreTranslate ──
        final baseUrl = prefs.getString('libretranslate_url') ?? 'https://libretranslate.com';
        // SECURITY: Read API keys from encrypted secure storage
        const secureStorage = FlutterSecureStorage();
        final apiKey = await secureStorage.read(key: 'libretranslate_api_key') ?? '';

        final body = <String, dynamic>{
          'q': plainText,
          'source': 'auto',
          'target': targetLang,
          'format': 'text',
        };
        if (apiKey.isNotEmpty) {
          body['api_key'] = apiKey;
        }

        final response = await http.post(
          Uri.parse('$baseUrl/translate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          translated = data['translatedText'];
        } else {
          String errMsg = 'LibreTranslate failed (${response.statusCode})';
          try {
            final errData = jsonDecode(response.body);
            errMsg = errData['error'] ?? errMsg;
          } catch (_) {}
          throw Exception(errMsg);
        }
      }

      setState(() {
        _translatedContent = translated ?? 'Translation failed';
        _isTranslating = false;
      });
    } catch (e) {
      setState(() => _isTranslating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: $e'), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: CyberpunkTheme.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _sheetTile(Icons.share_outlined, 'Share', () {
              Navigator.pop(ctx);
              SocialActions.shareStatus(widget.status);
            }),
            _sheetTile(Icons.open_in_browser_rounded, S.of(context).openInBrowser, () {
              Navigator.pop(ctx);
              final url = widget.status.url;
              if (url.isNotEmpty) {
              final uri = Uri.parse(url);
              if (uri.scheme == 'http' || uri.scheme == 'https') {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
            }),
            _sheetTile(Icons.link_rounded, S.of(context).copyLink, () {
              Navigator.pop(ctx);
              final url = widget.status.url;
              if (url.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).linkCopied),
                    backgroundColor: CyberpunkTheme.cardDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: CyberpunkTheme.textWhite, size: 22),
      title: Text(label, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 15)),
      onTap: onTap,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: CyberpunkTheme.backgroundBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (widget.status.hasMediaAttachments) _buildMedia(context),
          _buildActions(context),
          if (_favouritesCount > 0) _buildLikesCount(context),
          _buildCaption(context),
          if (widget.status.replies_count > 0) _buildViewComments(context),
          _buildTimeAgo(context),
          const SizedBox(height: 8),
          Container(height: 0.5, color: CyberpunkTheme.borderDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.3), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Hero(
                  tag: 'avatar_${widget.status.account.id}',
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: CyberpunkTheme.cardDark,
                    backgroundImage: widget.status.avatar.isNotEmpty
                        ? CachedNetworkImageProvider(widget.status.avatar)
                        : null,
                    child: widget.status.avatar.isEmpty
                        ? const Icon(Icons.person, size: 16, color: CyberpunkTheme.textTertiary)
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Text(
                widget.status.acct,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CyberpunkTheme.textWhite,
                ),
              ),
            ),
          ),
          GestureDetector(
          onTap: () => _showMoreSheet(context),
          child: const Icon(Icons.more_horiz_rounded, size: 20, color: CyberpunkTheme.textSecondary),
        ),
        ],
      ),
    );
  }

  int _mediaPageIndex = 0;

  Widget _buildMedia(BuildContext context) {
    final allMedia = widget.status.getAllMedia();
    final firstMedia = widget.status.getFirstMedia();
    final isVideoType = firstMedia != null && (firstMedia['type'] == 'video' || firstMedia['type'] == 'gifv');
    final isVideoExtension = widget.status.attach.toLowerCase().contains('.mp4') || widget.status.attach.toLowerCase().contains('.mov');
    final isVideo = isVideoType || isVideoExtension;

    // Multi-image carousel
    if (allMedia.length > 1) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 400,
            child: PageView.builder(
              itemCount: allMedia.length,
              onPageChanged: (index) => setState(() => _mediaPageIndex = index),
              itemBuilder: (context, index) {
                final media = allMedia[index];
                final url = media['url'] ?? '';
                final type = media['type'] ?? 'image';
                final isVid = type == 'video' || type == 'gifv';
                if (isVid) {
                  return SimpleVideoPlayer(url: url);
                }
                return GestureDetector(
                  onDoubleTap: _handleDoubleTap,
                  onTap: () => _openFullScreenImage(url),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: CyberpunkTheme.cardDark,
                      child: const Center(child: InstagramLoadingIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: CyberpunkTheme.cardDark,
                      child: const Icon(Icons.broken_image_outlined, color: CyberpunkTheme.textTertiary, size: 32),
                    ),
                  ),
                );
              },
            ),
          ),
          // Counter chip top-right
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_mediaPageIndex + 1}/${allMedia.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Dots at bottom
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(allMedia.length, (i) {
                return Container(
                  width: _mediaPageIndex == i ? 8 : 6,
                  height: _mediaPageIndex == i ? 8 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mediaPageIndex == i
                        ? CyberpunkTheme.neonCyan
                        : CyberpunkTheme.textTertiary.withOpacity(0.5),
                    boxShadow: _mediaPageIndex == i
                        ? [BoxShadow(color: CyberpunkTheme.neonCyan.withOpacity(0.5), blurRadius: 4)]
                        : null,
                  ),
                );
              }),
            ),
          ),
          // Like animation
          AnimatedBuilder(
            animation: _likeAnimation,
            builder: (context, child) {
              if (_likeAnimation.value == 0) return const SizedBox.shrink();
              final progress = _likeAnimation.value;
              double scale;
              double opacity;
              if (progress < 0.3) {
                scale = (progress / 0.3) * 1.2;
                opacity = 1.0;
              } else if (progress < 0.5) {
                scale = 1.2 - ((progress - 0.3) / 0.2) * 0.2;
                opacity = 1.0;
              } else {
                scale = 1.0;
                opacity = 1.0 - ((progress - 0.5) / 0.5);
              }
              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.0, 1.5),
                  child: const Icon(Icons.favorite, color: Color(0xFFFF00FF), size: 100),
                ),
              );
            },
          ),
        ],
      );
    }

    if (isVideo) {
      return SizedBox(
        width: double.infinity,
        height: 400,
        child: SimpleVideoPlayer(url: widget.status.attach),
      );
    }

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: () => _openFullScreenImage(widget.status.attach),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Hero(
            tag: 'post_image_${widget.status.id}',
            child: AspectRatio(
            aspectRatio: 1.0,
            child: CachedNetworkImage(
              imageUrl: widget.status.attach,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: CyberpunkTheme.cardDark,
                child: const Center(child: InstagramLoadingIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: CyberpunkTheme.cardDark,
                child: const Icon(Icons.broken_image_outlined, color: CyberpunkTheme.textTertiary, size: 32),
              ),
            ),
          ),
          ),
          AnimatedBuilder(
            animation: _likeAnimation,
            builder: (context, child) {
              if (_likeAnimation.value == 0) return const SizedBox.shrink();
              // Scale: 0 -> 1.2 (at 40%) -> 1.0 (at 60%) -> 1.0 (hold) -> fade out
              final progress = _likeAnimation.value;
              double scale;
              double opacity;
              if (progress < 0.3) {
                // Scale up to 1.2
                scale = (progress / 0.3) * 1.2;
                opacity = 1.0;
              } else if (progress < 0.5) {
                // Settle from 1.2 to 1.0
                scale = 1.2 - ((progress - 0.3) / 0.2) * 0.2;
                opacity = 1.0;
              } else {
                // Hold at 1.0 and fade out
                scale = 1.0;
                opacity = 1.0 - ((progress - 0.5) / 0.5);
              }
              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.0, 1.5),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFFF00FF), // cyberpunk neon pink
                    size: 100,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          _ActionIcon(
            icon: _isFavorited ? Icons.favorite : Icons.favorite_border_rounded,
            color: _isFavorited ? CyberpunkTheme.neonPink : CyberpunkTheme.textWhite,
            onTap: () {
              widget.onLike?.call();
              setState(() {
                _isFavorited = !_isFavorited;
                if (_isFavorited) {
                  _favouritesCount++;
                  _likeAnimationController.forward(from: 0.0);
                } else {
                  _favouritesCount--;
                }
              });
            },
          ),
          const SizedBox(width: 14),
          _ActionIcon(
            icon: Icons.mode_comment_outlined,
            onTap: () => widget.onComment?.call(),
          ),
          const SizedBox(width: 14),
          _ActionIcon(
            icon: Icons.send_outlined,
            onTap: () => widget.onShare?.call(),
          ),
          const Spacer(),
          _ActionIcon(
            icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: _isBookmarked ? CyberpunkTheme.neonCyan : null,
            onTap: () {
              widget.onBookmark?.call();
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Text(
        '$_favouritesCount ${_favouritesCount == 1 ? S.of(context).like : S.of(context).likes}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CyberpunkTheme.textWhite,
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    if (widget.status.content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
             widget.status.acct,
             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: CyberpunkTheme.textWhite),
           ),
           // TODO(security): Sanitize HTML content from server before rendering to prevent XSS.
           // Consider using a sanitizer package like html_sanitize or a whitelist approach.
           Html(
             data: widget.status.content,
             style: {
               "body": Style(
                 margin: Margins.zero,
                 padding: HtmlPaddings.zero,
                 fontSize: FontSize(14),
                 color: CyberpunkTheme.textWhite,
                 lineHeight: LineHeight(1.4),
               ),
               "a": Style(
                 color: CyberpunkTheme.neonCyan,
                 textDecoration: TextDecoration.none,
                 fontWeight: FontWeight.w500,
               ),
             },
             onLinkTap: (url, attributes, element) async {
                if (url == null) return;
                
                if (url.contains('/tags/')) {
                  try {
                    final uri = Uri.parse(url);
                    final segments = uri.pathSegments;
                    final tagIndex = segments.indexOf('tags');
                    if (tagIndex != -1 && tagIndex + 1 < segments.length) {
                      final tag = segments[tagIndex + 1];
                      Navigator.pushNamed(context, '/TagTimeline', arguments: {'tag': tag});
                      return;
                    }
                  } catch (e) {
                    // ignore
                  }
                }
                
                try {
                  final uri = Uri.parse(url);
                  if ((uri.scheme == 'http' || uri.scheme == 'https') && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  // ignore
                }
             },
           ),
           // Translated content
           if (_translatedContent != null)
             Container(
               margin: const EdgeInsets.only(top: 6),
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 color: CyberpunkTheme.neonCyan.withOpacity(0.06),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.15)),
               ),
               child: Text(
                 _translatedContent!,
                 style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14, height: 1.4),
               ),
             ),
           // Translate button
           GestureDetector(
             onTap: _translateContent,
             child: Padding(
               padding: const EdgeInsets.only(top: 4),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   if (_isTranslating)
                     const SizedBox(
                       width: 12, height: 12,
                       child: CircularProgressIndicator(strokeWidth: 1.5, color: CyberpunkTheme.neonCyan),
                     )
                   else
                     Icon(
                       _translatedContent != null ? Icons.undo_rounded : Icons.translate_rounded,
                       size: 14,
                       color: CyberpunkTheme.neonCyan.withOpacity(0.7),
                     ),
                   const SizedBox(width: 4),
                   Text(
                     _translatedContent != null ? S.of(context).showOriginal : S.of(context).translate,
                     style: TextStyle(
                       color: CyberpunkTheme.neonCyan.withOpacity(0.7),
                       fontSize: 13,
                       fontWeight: FontWeight.w500,
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

  Widget _buildViewComments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: GestureDetector(
        onTap: widget.onComment,
        child: Text(
          '${S.of(context).viewAllComments} (${widget.status.replies_count})',
          style: const TextStyle(fontSize: 14, color: CyberpunkTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildTimeAgo(BuildContext context) {
    DateTime? createdAt;
    try {
      if (widget.status.created_at.isNotEmpty) {
        createdAt = DateTime.parse(widget.status.created_at);
      }
    } catch (_) {}

    if (createdAt == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Text(
        timeago.format(createdAt, locale: 'en_short'),
        style: const TextStyle(fontSize: 12, color: CyberpunkTheme.textTertiary),
      ),
    );
  }
}

/// Small action icon with consistent sizing
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 24, color: color ?? CyberpunkTheme.textWhite),
      ),
    );
  }
}


// ── Full-screen image viewer with pinch-to-zoom ──────────────────────────
class _FullScreenImageView extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageView({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  final TransformationController _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformController.value = Matrix4.identity()
        ..translate(-position.dx, -position.dy)
        ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // Only allow swipe-to-close when not zoomed
          if (_transformController.value == Matrix4.identity() &&
              details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: CyberpunkTheme.textTertiary,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
