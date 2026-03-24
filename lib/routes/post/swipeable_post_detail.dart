import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/routes/post/post_detail_page.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';

/// Wraps PostDetailPage in a horizontal PageView for swiping between posts.
/// Falls back to a single PostDetailPage if no statusList is provided.
class SwipeablePostDetail extends StatefulWidget {
  final ApiService apiService;
  final List<Status> statusList;
  final int initialIndex;

  const SwipeablePostDetail({
    Key? key,
    required this.apiService,
    required this.statusList,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<SwipeablePostDetail> createState() => _SwipeablePostDetailState();
}

class _SwipeablePostDetailState extends State<SwipeablePostDetail> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statusList.length <= 1) {
      return PostDetailPage(
        apiService: widget.apiService,
        post: widget.statusList.isNotEmpty
            ? widget.statusList.first
            : Status.empty(),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: widget.statusList.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
      },
      itemBuilder: (context, index) {
        return PostDetailPage(
          key: ValueKey(widget.statusList[index].id),
          apiService: widget.apiService,
          post: widget.statusList[index],
        );
      },
    );
  }
}
