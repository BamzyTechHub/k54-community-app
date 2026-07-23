import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/k54_route.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/profile/screens/profile_page.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/features/activity/screens/timeline_page.dart';
import 'package:k54_mobile/features/communication/communication_navigation.dart';
import 'package:k54_mobile/features/activity/screens/create_post_page.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/features/notifications/repositories/notifications_repository.dart';
import 'package:k54_mobile/features/notifications/screens/notifications_page.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/core/widgets/unread_badge.dart';
import 'package:k54_mobile/features/search/screens/search_results_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  // Stable, typed key so the feed widget isn't torn down and remounted on
  // every HomePage rebuild (it previously used ValueKey(DateTime.now()...),
  // which forced a full remount + refetch on every rebuild) - typed so a
  // new post can trigger a real refetch via refreshTimeline() instead of
  // relying on a HomePage setState() that, thanks to the stable key,
  // never actually reaches the feed at all.
  final GlobalKey<TimelinePageState> _timelineKey = GlobalKey<TimelinePageState>();

  @override
  void initState() {
    super.initState();
    // Warm the unread-messages/notifications badges so they're already
    // correct the moment the home page renders, without requiring the
    // user to open Messages/Notifications first.
    _warmUnreadBadge();
  }

  Future<void> _warmUnreadBadge() async {
    try {
      await MessagingRepository.instance.refreshThreads();
    } catch (_) {
      // Non-fatal — badge just stays at 0 until the next successful refresh.
    }
    try {
      await NotificationsRepository.instance.getNotifications();
    } catch (_) {
      // Non-fatal — same reasoning as above.
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
  backgroundColor: AppColors.white,

 bottomNavigationBar: const K54BottomNavigation(
  currentIndex: 0,
),

  body: SafeArea(

        child: Column(

          children: [

            // Header - exact measurements pulled from the K54 HOME PAGE
            // Figma frame (node 571:714, "Chip") via the REST API
            // 2026-07-16: 29px avatar, 24px-tall pill search bar
            // (fill #FCF8ED, text/icon #1A1A1A - NOT the tan/gold read
            // from the old stale file this used to cite), 24px icons,
            // 19px gaps between every element. Supersedes the taller,
            // tan/gold header used previously.
            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),


              child: Row(

                children: [

                  TapScale(
                    onTap: () {
                      Navigator.push(context, k54Route(ProfilePage()));
                    },
                    borderRadius: BorderRadius.circular(14.5),
                    child: FutureBuilder(
                      future: AuthService().getCurrentUser(),
                      builder: (context, snapshot) {
                        String avatar = "";
                        String name = "";
                        if (snapshot.hasData) {
                          final user = (snapshot.data as dynamic).data;
                          avatar = user["avatar_urls"]?["thumb"] ??
                              user["avatar_urls"]?["full"] ??
                              "";
                          name = user["name"] ?? "";
                        }
                        return UserAvatar(imageUrl: avatar, name: name, radius: 14.5);
                      },
                    ),
                  ),

                  const SizedBox(width: 19),

                  Expanded(
                    child: TapScale(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchResultsPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(9999),
                      // Was height 24 - noticeably smaller than the AI
                      // page's search bar - direct tester feedback asking
                      // for that same size everywhere.
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCF8ED),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          children: [
                            // Exact SVG export of node 571:803 ("Search
                            // Icon"), not a Material Icon approximation -
                            // pulled directly from the Figma images API
                            // 2026-07-17.
                            SvgPicture.asset("assets/icons/icon_search.svg", width: 20, height: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Search",
                              style: TextStyle(color: AppColors.jetBlack, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 19),

                  // Create Post - gold pencil, matches "tabler:edit-filled"
                  TapScale(
                    onTap: () async {
                      final created = await Navigator.push<Post>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatePostPage(),
                        ),
                      );
                      // Instant, local insert using the real Post the
                      // create call already returned - no refetch, no
                      // wait on server/CDN propagation. See
                      // TimelinePageState.prependPost's doc comment.
                      if (created != null && mounted) {
                        _timelineKey.currentState?.prependPost(created);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Posted"), duration: Duration(seconds: 2)),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: SvgPicture.asset("assets/icons/icon_edit.svg", width: 24, height: 24),
                  ),

                  const SizedBox(width: 19),

                  // Messages - matches "cryptocurrency:chat", 24px gold.
                  // The bell that used to sit here is removed - it isn't
                  // part of this frame at all. NOT relocated to
                  // ProfileMenu or anywhere else - that menu is itself a
                  // confirmed Figma component with a fixed item set, and
                  // adding to it would be the same "invent UI not in
                  // Figma" mistake. NotificationsPage is currently
                  // unreachable from any nav point - flagged to the user
                  // rather than guessed at.
                  TapScale(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunicationNavigation(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: UnreadBadge(
                      count: MessagingRepository.instance.unreadCount,
                      child: SvgPicture.asset("assets/icons/icon_chat.svg", width: 24, height: 24),
                    ),
                  ),

                  const SizedBox(width: 19),

                  // Notifications - previously removed from this header to
                  // match the Figma frame exactly, but that left
                  // NotificationsPage (fully real - loads/marks-read
                  // against the confirmed BuddyBoss endpoint) completely
                  // unreachable from anywhere in the app. Restored using a
                  // Material bell icon tinted to match the other icons'
                  // exact gold (#AB8000, read directly from icon_chat.svg's
                  // own fill) since no notification SVG was ever exported
                  // from Figma for this frame - same size/spacing/badge
                  // treatment as the Messages icon for visual consistency.
                  TapScale(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: UnreadBadge(
                      count: NotificationsRepository.instance.unreadCount,
                      child: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFFAB8000)),
                    ),
                  ),

                  const SizedBox(width: 19),

                  // Shop - matches "maki:shop", 24px gold.
                  TapScale(
                    onTap: () {
                      // The real K54 store (Kafe' 54 merch on Printify) - confirmed live
                      // and reachable 2026-07-10. Opens externally rather than an in-app
                      // WebView, since an in-app WebView's back button was reportedly
                      // misbehaving before.
                      launchUrl(
                        Uri.parse("https://kafe-54.printify.me/"),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: SvgPicture.asset("assets/icons/icon_shop.svg", width: 24, height: 24),
                  ),
                ],

              ),

            ),


            // Feed
             Expanded(
  child: TimelinePage(
    key: _timelineKey,
  ),
),

          ],

        ),

      ),

    );

  }

}