// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:io';

import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/routes/timeline/widget/statusCard/StatusCard.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class TagTimeline extends StatefulWidget {
  final ApiService apiService;
  final String tag;

  const TagTimeline({Key? key, required this.apiService, required this.tag})
      : super(key: key);

  @override
  State<TagTimeline> createState() => _TagTimelineState();
}

class _TagTimelineState extends State<TagTimeline> {
  static const _pageSize = 20;

  late final PagingController<String?, Status> _pagingController =
      PagingController(
    getNextPageKey: (state) {
      if ((state.pages ?? []).isEmpty) return "";
      final lastPage = state.pages!.last;
      if (lastPage.length < _pageSize) return null;
      return lastPage.last.id;
    },
    fetchPage: (pageKey) async {
      try {
        final key = (pageKey == "" || pageKey == null) ? null : pageKey;
        return await widget.apiService
            .getTimelineTag(widget.tag, key, _pageSize);
      } catch (error) {
        rethrow;
      }
    },
  );

  bool _isFollowingTag = false;
  bool _isToggling = false;
  List<Map<String, dynamic>> _relatedTags = [];

  @override
  void initState() {
    super.initState();
    _loadTagMeta();
  }

  Future<void> _loadTagMeta() async {
    try {
      // Check if tag is followed by looking at followed tags list
      final followedTags = await widget.apiService.getFollowedTags(limit: 200);
      final isFollowed = followedTags.any((t) =>
          (t['name'] ?? '').toString().toLowerCase() ==
          widget.tag.toLowerCase());

      final related = await widget.apiService.getRelatedTags(widget.tag);

      if (mounted) {
        setState(() {
          _isFollowingTag = isFollowed;
          _relatedTags = related;
        });
      }
    } catch (e) {
      // Silently fail — non-critical
    }
  }

  Future<void> _toggleFollowTag() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      bool ok;
      if (_isFollowingTag) {
        ok = await widget.apiService.unfollowTag(widget.tag);
      } else {
        ok = await widget.apiService.followTag(widget.tag);
      }
      if (ok && mounted) {
        setState(() => _isFollowingTag = !_isFollowingTag);
      }
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _isToggling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A0F),
              const Color(0xFF0D0D15),
              const Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('#${widget.tag}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: const Color(0xFF00F3FF).withOpacity(0.3),
                          width: 1))),
            ),
            actions: [
              _isToggling
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF00F3FF))),
                    )
                  : TextButton.icon(
                      icon: Icon(
                        _isFollowingTag
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        color: _isFollowingTag
                            ? const Color(0xFF00F3FF)
                            : Colors.white70,
                        size: 20,
                      ),
                      label: Text(
                        _isFollowingTag ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: _isFollowingTag
                              ? const Color(0xFF00F3FF)
                              : Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: _toggleFollowTag,
                    ),
            ],
          ),
          body: Column(
            children: [
              // Related tags chips
              if (_relatedTags.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _relatedTags.take(10).map((t) {
                        final name = t['name'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TagTimeline(
                                      apiService: widget.apiService, tag: name),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F3FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFF00F3FF)
                                        .withOpacity(0.3)),
                              ),
                              child: Text(
                                '#$name',
                                style: const TextStyle(
                                    color: Color(0xFF00F3FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              // Post list
              Expanded(
                child: RefreshIndicator(
                  color: CyberpunkTheme.neonCyan,
                  backgroundColor: CyberpunkTheme.cardDark,
                  onRefresh: () => Future.sync(_pagingController.refresh),
                  child: ValueListenableBuilder<PagingState<String?, Status>>(
                    valueListenable: _pagingController,
                    builder: (context, state, child) =>
                        PagedListView<String?, Status>(
                      state: state,
                      fetchNextPage: _pagingController.fetchNextPage,
                      physics: const ClampingScrollPhysics(),
                      builderDelegate: PagedChildBuilderDelegate<Status>(
                        itemBuilder: (context, item, index) => StatusCard(
                          item,
                          apiService: widget.apiService,
                        ),
                        firstPageErrorIndicatorBuilder: (context) => Center(
                          child: Text('Error: ${_pagingController.error}'),
                        ),
                        noItemsFoundIndicatorBuilder: (context) => Center(
                          child: Text('No posts found for #${widget.tag}'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
