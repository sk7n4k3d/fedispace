import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/widgets/skeleton_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;


class Profile extends StatefulWidget {
  final ApiService apiService;

  const Profile({Key? key, required this.apiService}) : super(key: key);

  @override
  State<Profile> createState() => _Profile();
}

class _Profile extends State<Profile> {
  final apiService = ApiService();
  int page = 1;
  Account? account;
  dynamic _userAccount;
  AccountUsers? accountUsers;

  late Object jsonData;
  List<Map<String, dynamic>> arrayOfProducts = [];
  bool isPageLoading = false;

  String getFormattedNumber(int? inputNumber) {
    if (inputNumber == null) return '0';
    if (inputNumber >= 1000000) {
      return "${(inputNumber / 1000000).toStringAsFixed(1)}M";
    } else if (inputNumber >= 10000) {
      return "${(inputNumber / 1000).toStringAsFixed(1)}K";
    }
    return inputNumber.toString();
  }

  Future<Object> fetchAccount() async {
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    if (arguments["id"] != null) {
      AccountUsers currentAccount =
          (await widget.apiService.getUserAccount(arguments["id"].toString()));
      _userAccount = currentAccount;
      return accountUsers = currentAccount;
    } else {
      Account currentAccount = await widget.apiService.getAccount();
      _userAccount = currentAccount;
      return account = currentAccount;
    }
  }

  void makeRebuild() {
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _callAPIToGetListOfData() async {
    if (isPageLoading == true || (isPageLoading == false && page == 1)) {
      final responseDic;
      if (arrayOfProducts.length == 0) {
        responseDic = await widget.apiService.getUserStatus(_userAccount.id, page, "0");
      } else {
        responseDic = await widget.apiService.getUserStatus(_userAccount.id, page, arrayOfProducts[arrayOfProducts.length - 1]["id"]);
      }
      List<Map<String, dynamic>> temArr = List<Map<String, dynamic>>.from(responseDic);
      if (page == 1) {
        arrayOfProducts = temArr;
      } else {
        arrayOfProducts.addAll(temArr);
      }
      return arrayOfProducts;
    }
    return arrayOfProducts;
  }

  String avatarUrl() {
    var domain = widget.apiService.domainURL();
    if (_userAccount!.avatarUrl.contains("://")) {
      return _userAccount!.avatarUrl.toString();
    } else {
      return domain.toString() + _userAccount!.avatarUrl;
    }
  }

  final ScrollController _scrollController = ScrollController();
  late Future<Object> _accountFuture;
  late Future<List<Map<String, dynamic>>> _dataFuture;
  bool _accountLoaded = false;

  @override
  void initState() {
    super.initState();
    // Defer until after first frame so ModalRoute is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final future = fetchAccount().then((result) {
        _dataFuture = _callAPIToGetListOfData();
        if (mounted) {
          setState(() {
            _accountLoaded = true;
          });
        }
        return result;
      });
      setState(() {
        _accountFuture = future;
      });
    });
    _scrollController.addListener(() async {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (arrayOfProducts.length >= (16 * page)) {
          page++;
          isPageLoading = true;
          await _callAPIToGetListOfData();
          isPageLoading = false;
          makeRebuild();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_accountLoaded) {
      return Scaffold(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        body: const SingleChildScrollView(child: ProfileSkeleton()),
      );
    }
    return FutureBuilder<Object>(
      future: _accountFuture,
      builder: (BuildContext context, AsyncSnapshot<Object> snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            backgroundColor: CyberpunkTheme.backgroundBlack,
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Collapsing app bar with avatar
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: CyberpunkTheme.backgroundBlack,
                  leading: Navigator.canPop(context)
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, size: 22, color: CyberpunkTheme.textWhite),
                      onPressed: () => Navigator.pushNamed(context, '/Notification'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 22, color: CyberpunkTheme.textWhite),
                      onPressed: () => Navigator.pushNamed(context, '/Settings'),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CyberpunkTheme.neonCyan.withOpacity(0.10),
                            CyberpunkTheme.backgroundBlack,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Profile info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + Stats row
                        Row(
                          children: [
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CyberpunkTheme.neonCyan.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CyberpunkTheme.neonCyan.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundColor: CyberpunkTheme.cardDark,
                                  backgroundImage: CachedNetworkImageProvider(avatarUrl()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Stats
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem(S.of(context).posts, _userAccount.statuses_count),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/FollowersList', arguments: {
                                      'userId': _userAccount.id,
                                      'type': 'followers',
                                    }),
                                    child: _buildStatItem(S.of(context).followers, _userAccount.followers_count),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/FollowersList', arguments: {
                                      'userId': _userAccount.id,
                                      'type': 'following',
                                    }),
                                    child: _buildStatItem(S.of(context).following, _userAccount.following_count),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Display name
                        Text(
                          _userAccount?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CyberpunkTheme.textWhite,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // Username
                        Text(
                          '@${_userAccount?.acct ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: CyberpunkTheme.textSecondary,
                          ),
                        ),

                        // Bio
                        if (_userAccount?.note != null && _userAccount.note.toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: html.Html(
                              data: _userAccount.note,
                              style: {
                                "body": html.Style(
                                  margin: html.Margins.zero,
                                  padding: html.HtmlPaddings.zero,
                                  fontSize: html.FontSize(14),
                                  color: CyberpunkTheme.textWhite.withOpacity(0.9),
                                  lineHeight: html.LineHeight(1.4),
                                ),
                                "a": html.Style(
                                  color: CyberpunkTheme.neonCyan,
                                  textDecoration: TextDecoration.none,
                                ),
                              },
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pushNamed(context, '/EditProfile'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: CyberpunkTheme.textWhite,
                                  side: const BorderSide(color: CyberpunkTheme.borderDark),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text(S.of(context).editProfile, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Container(height: 0.5, color: CyberpunkTheme.borderDark),
                      ],
                    ),
                  ),
                ),

                // Grid
                SliverToBoxAdapter(
                  child: FutureBuilder(
                    future: _accountLoaded ? _dataFuture : null,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 2),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1.5,
                            mainAxisSpacing: 1.5,
                            childAspectRatio: 1,
                          ),
                          itemCount: snapshot.data.length,
                          itemBuilder: (BuildContext context, int index) {
                            final media = snapshot.data[index]["media_attachments"][0];
                            final String url = media["url"];
                            final String type = media["type"] ?? "image";
                            final bool isVideo = type == "video" || type == "gifv";

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/statusDetail', arguments: {
                                  'statusId': snapshot.data[index]["id"],
                                  'apiService': widget.apiService,
                                });
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  isVideo
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _ProfileVideoItem(url: url, previewUrl: media["preview_url"]),
                                            const Center(
                                              child: Icon(Icons.play_circle_outline, color: Colors.white, size: 36),
                                            ),
                                          ],
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: url,
                                          placeholder: (context, url) => Container(
                                            color: CyberpunkTheme.cardDark,
                                            child: const Center(child: InstagramLoadingIndicator(size: 16)),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: CyberpunkTheme.cardDark,
                                            child: const Icon(Icons.broken_image_outlined, color: CyberpunkTheme.textTertiary, size: 20),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                  if ((snapshot.data[index]["media_attachments"] as List).length > 1)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(
                                        Icons.collections_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(child: Text(S.of(context).error, style: const TextStyle(color: CyberpunkTheme.textSecondary))),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 1.5,
                          mainAxisSpacing: 1.5,
                          childAspectRatio: 1,
                        ),
                        itemCount: 9,
                        itemBuilder: (_, __) => SkeletonLoading(
                          child: Container(color: CyberpunkTheme.cardDark),
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: CyberpunkTheme.backgroundBlack,
            body: Center(child: Text(S.of(context).error, style: const TextStyle(color: CyberpunkTheme.textSecondary))),
          );
        }
        return Scaffold(
          backgroundColor: CyberpunkTheme.backgroundBlack,
          body: const SingleChildScrollView(child: ProfileSkeleton()),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          getFormattedNumber(value),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CyberpunkTheme.textWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CyberpunkTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Lightweight video thumbnail using preview image instead of full VideoPlayerController.
/// VideoPlayerController should only be created when the user taps to play.
class _ProfileVideoItem extends StatelessWidget {
  final String url;
  final String? previewUrl;
  const _ProfileVideoItem({Key? key, required this.url, this.previewUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (previewUrl != null && previewUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: previewUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: CyberpunkTheme.cardDark,
          child: const Center(child: InstagramLoadingIndicator(size: 16)),
        ),
        errorWidget: (context, url, error) => Container(
          color: CyberpunkTheme.cardDark,
          child: const Icon(Icons.videocam_outlined, color: CyberpunkTheme.textTertiary, size: 24),
        ),
      );
    }
    return Container(
      color: CyberpunkTheme.cardDark,
      child: const Icon(Icons.videocam_outlined, color: CyberpunkTheme.textTertiary, size: 24),
    );
  }
}
