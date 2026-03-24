import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fedispace/core/drafts_manager.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/routes/post/send.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Page showing saved post drafts with cyberpunk glassmorphism styling.
class DraftsPage extends StatefulWidget {
  final ApiService apiService;

  const DraftsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  final DraftsManager _manager = DraftsManager();
  List<PostDraft> _drafts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final drafts = await _manager.getDrafts();
    if (mounted) {
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDraft(PostDraft draft) async {
    await _manager.deleteDraft(draft.id);
    await _loadDrafts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft deleted'),
          backgroundColor: CyberpunkTheme.cardDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openDraft(PostDraft draft) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendPosts(
          apiService: widget.apiService,
          draft: draft,
        ),
      ),
    ).then((_) => _loadDrafts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonPink],
              ).createShader(bounds),
              child: Text(
                'DRAFTS',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            if (_drafts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: CyberpunkTheme.neonCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${_drafts.length}',
                  style: const TextStyle(
                    color: CyberpunkTheme.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan),
            )
          : _drafts.isEmpty
              ? _buildEmptyState()
              : _buildDraftsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.drafts_outlined,
            size: 64,
            color: CyberpunkTheme.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No drafts yet',
            style: TextStyle(
              color: CyberpunkTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved drafts will appear here',
            style: TextStyle(
              color: CyberpunkTheme.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return Dismissible(
          key: Key(draft.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.redAccent.withOpacity(0.2),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: CyberpunkTheme.cardDark,
                title: const Text('Delete Draft', style: TextStyle(color: CyberpunkTheme.textWhite)),
                content: const Text(
                  'This draft will be permanently deleted.',
                  style: TextStyle(color: CyberpunkTheme.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (_) => _deleteDraft(draft),
          child: _DraftCard(
            draft: draft,
            onTap: () => _openDraft(draft),
          ),
        );
      },
    );
  }
}

class _DraftCard extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onTap;

  const _DraftCard({required this.draft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasMedia = draft.mediaFilePaths.isNotEmpty;
    final firstMediaExists = hasMedia && File(draft.mediaFilePaths.first).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.07),
              Colors.white.withOpacity(0.03),
            ],
          ),
          border: Border.all(
            color: CyberpunkTheme.glassBorder,
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: CyberpunkTheme.cardDark,
                    border: Border.all(
                      color: CyberpunkTheme.borderDark,
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: firstMediaExists
                        ? Image.file(
                            File(draft.mediaFilePaths.first),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderIcon(),
                          )
                        : _placeholderIcon(),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Caption preview
                      Text(
                        draft.caption.isNotEmpty ? draft.caption : '(No caption)',
                        style: TextStyle(
                          color: draft.caption.isNotEmpty
                              ? CyberpunkTheme.textWhite
                              : CyberpunkTheme.textTertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Meta row
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: CyberpunkTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(draft.createdAt),
                            style: const TextStyle(
                              color: CyberpunkTheme.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                          if (hasMedia) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.photo_library_rounded,
                                size: 12, color: CyberpunkTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${draft.mediaFilePaths.length}',
                              style: const TextStyle(
                                color: CyberpunkTheme.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (draft.sensitive) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.warning_amber_rounded,
                                size: 12, color: Colors.orange.withOpacity(0.7)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CyberpunkTheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: CyberpunkTheme.cardDark,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: CyberpunkTheme.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}
