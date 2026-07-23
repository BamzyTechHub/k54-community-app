import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/features/activity/widgets/comments_sheet.dart';
import 'package:k54_mobile/features/live_video/models/live_channel_status.dart';
import 'package:k54_mobile/features/live_video/repositories/live_video_repository.dart';

/// Real live-stream viewer, opened by tapping a WPStream "I'm live"
/// activity post (see Post.isLiveStreamActivity). Polls the confirmed-real
/// event-status endpoint so a stream that goes offline while being watched
/// is reflected honestly, plays the real HLS feed via video_player, and
/// reuses the app's existing comment sheet for [post] rather than building
/// a second, parallel comment system.
class LiveWatchPage extends StatefulWidget {
  final Post post;

  const LiveWatchPage({super.key, required this.post});

  @override
  State<LiveWatchPage> createState() => _LiveWatchPageState();
}

class _LiveWatchPageState extends State<LiveWatchPage> {
  static const _pollInterval = Duration(seconds: 8);

  LiveChannelStatus? _status;
  bool _loading = true;
  Object? _error;
  Timer? _pollTimer;
  VideoPlayerController? _videoController;
  String _playingUrl = '';

  WebSocketChannel? _viewsSocket;
  int? _viewerCount;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _videoController?.dispose();
    _viewsSocket?.sink.close();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final status = await LiveVideoRepository.instance.getStatusForUser(widget.post.userId);
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
      if (status.isLive && status.hlsUrl.isNotEmpty && status.hlsUrl != _playingUrl) {
        _initVideo(status.hlsUrl);
      } else if (!status.isLive) {
        _videoController?.dispose();
        _videoController = null;
        _playingUrl = '';
      }
      if (status.isLive && status.viewsSocketUrl.isNotEmpty) {
        _connectViewsSocket(status.viewsSocketUrl);
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _initVideo(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _playingUrl = url;
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _videoController?.dispose();
      setState(() => _videoController = controller);
      controller.play();
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _videoController = null);
    }
  }

  /// Real-time viewer count - protocol confirmed live 2026-07-22 against
  /// an actual active broadcast: this socket pushes small JSON messages
  /// shaped `{"type": "viewerCount", "data": 1}` (and separately
  /// `{"type": "onair", "data": true, ...}`, not used here). Anything else
  /// received is ignored rather than guessed at.
  void _connectViewsSocket(String url) {
    if (_viewsSocket != null) return;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _viewsSocket = channel;
      channel.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message.toString());
            if (decoded is Map && decoded['type'] == 'viewerCount') {
              final count = int.tryParse('${decoded['data']}');
              if (count != null && mounted) {
                setState(() => _viewerCount = count);
              }
            }
          } catch (_) {
            // Not JSON, or a shape we don't recognize - ignored rather
            // than guessed at.
          }
        },
        onError: (_) {},
        cancelOnError: true,
      );
    } catch (_) {
      _viewsSocket = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final status = _status;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  ),
                  UserAvatar(imageUrl: post.profileImage, name: post.username, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: GoogleFonts.lato(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (_viewerCount != null)
                          Text(
                            "$_viewerCount watching",
                            style: GoogleFonts.poppins(color: AppColors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (_loading && status == null)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white54),
                    )
                  else if (status?.isLive == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "LIVE",
                        style: GoogleFonts.lato(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "OFFLINE",
                        style: GoogleFonts.lato(color: AppColors.white70, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _buildBody(status)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => CommentsSheet.show(context, post),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mode_comment_outlined, color: AppColors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                post.comments > 0 ? "${post.comments} comments" : "Say something...",
                                style: GoogleFonts.poppins(color: AppColors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LiveChannelStatus? status) {
    if (_error != null) {
      return _offlineState("Couldn't load this stream", subtitle: "$_error");
    }
    if (_loading && status == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.white));
    }
    if (status == null || !status.isLive) {
      return _offlineState(
        "${widget.post.username} isn't live right now",
        subtitle: "Check back when they go live again.",
      );
    }

    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator(color: AppColors.white));
  }

  Widget _offlineState(String title, {required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: AppColors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
