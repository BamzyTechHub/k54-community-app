import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/live_video/models/live_channel_status.dart';
import 'package:k54_mobile/features/live_video/repositories/live_video_repository.dart';

/// Real "My Live Video" management view - mirrors the real website exactly
/// (screenshotted 2026-07-23): a Channel Controls box with a genuine
/// ON/OFF toggle and a Preview box, versus a plain read-only viewer when
/// looking at someone else's profile.
///
/// [LiveChannelStatus.isLive] (`started` from event-status) is confirmed
/// live 2026-07-23 to mean "channel is ON", not "actively broadcasting
/// video" - the real site's own preview stays a black box with just
/// "Viewers: N" until a webcam/OBS actually pushes video, same as this
/// app's own event-status calls showed. Turn On/Off are confirmed real
/// ajax actions (wpstream_give_me_live_uri with a start_onboarding param,
/// and wpstream_turn_of_channel respectively - see the bridge file).
///
/// External App (real RTMP url), View Channel (real embed player), and
/// Share (real embed link) are all wired to confirmed-real data. Webcam
/// broadcast and Live Stats aren't: webcam needs the separate WebRTC/WHIP
/// broadcasting build (a much bigger, deliberately-deferred effort), and
/// Live Stats' real ajax action hasn't been captured yet - same honesty
/// as the site's own still-unbuilt GoLivePage rather than faking either.
class ProfileLiveVideoTab extends StatefulWidget {
  final String? userId;

  const ProfileLiveVideoTab({super.key, this.userId});

  @override
  State<ProfileLiveVideoTab> createState() => _ProfileLiveVideoTabState();
}

class _ProfileLiveVideoTabState extends State<ProfileLiveVideoTab> {
  String? _channelId;
  String? _channelTitle;
  LiveChannelStatus? _status;
  bool _loading = true;
  bool _toggling = false;

  bool get _isOwnProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      String userId = widget.userId ?? '';
      if (userId.isEmpty) {
        final response = await AuthService().getCurrentUser();
        userId = (response.data['id'] ?? '').toString();
      }
      final channelId = await LiveVideoRepository.instance.getChannelIdForUser(userId);
      final status = channelId == null
          ? LiveChannelStatus.offline
          : await LiveVideoRepository.instance.getEventStatus(channelId);
      if (mounted) {
        setState(() {
          _channelId = channelId;
          _channelTitle = channelId != null ? "Channel #$channelId" : null;
          _status = status;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleChannel() async {
    final channelId = _channelId;
    if (channelId == null || _toggling) return;
    final wasOn = _status?.isLive == true;
    setState(() => _toggling = true);
    try {
      if (wasOn) {
        await LiveVideoRepository.instance.turnOffChannel(channelId);
      } else {
        await LiveVideoRepository.instance.turnOnChannel(channelId);
      }
      // Optimistic update rather than an immediate re-fetch - WPStream
      // caches event-status server-side (confirmed live 2026-07-23, the
      // `$event_data_for_transient` cache found while investigating this),
      // so a re-check called right after a toggle can return a stale
      // "unchanged" result even though the toggle itself succeeded. Trust
      // the action that just succeeded; the page's own periodic refresh
      // (if any) reconciles with the real state shortly after anyway.
      if (mounted) {
        final current = _status;
        setState(() {
          _status = LiveChannelStatus(
            channelId: channelId,
            isLive: !wasOn,
            hlsUrl: current?.hlsUrl ?? '',
            posterUrl: current?.posterUrl ?? '',
            channelTitle: current?.channelTitle ?? '',
            chatUrl: current?.chatUrl ?? '',
            viewsSocketUrl: current?.viewsSocketUrl ?? '',
          );
          _toggling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _toggling = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't update channel: $e")));
      }
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature isn't available yet")),
    );
  }

  /// Real RTMP ingest URL, confirmed live 2026-07-23 - same value the
  /// site's own "Go Live With External Streaming App" screen shows, for
  /// pasting into OBS/other broadcasting software.
  void _showExternalAppInfo() {
    final url = _status?.broadcastUrl ?? '';
    if (url.isEmpty) {
      _comingSoon("Going live with an external app");
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => K54Dialog(
        title: "Go Live With an External App",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Paste this server URL into OBS or your streaming software's stream settings:"),
            const SizedBox(height: 10),
            SelectableText(url, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied")));
            },
            child: const Text("Copy"),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Close")),
        ],
      ),
    );
  }

  /// Opens the real public WPStream embed player - confirmed live
  /// 2026-07-23 - the same page anyone watching this channel would see.
  Future<void> _viewChannel() async {
    final url = _status?.embedUrl ?? '';
    if (url.isEmpty) {
      _comingSoon("Viewing this channel");
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _shareChannel() {
    final url = _status?.embedUrl ?? '';
    SharePlus.instance.share(
      ShareParams(
        text: url.isNotEmpty ? "Watch my live channel on K54!\n$url" : "Check out my live channel on K54!",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    if (_channelId == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EFD9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "No live channel yet",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return _isOwnProfile ? _ownManagementView() : _readOnlyPreview();
  }

  Widget _ownManagementView() {
    final isOn = _status?.isLive ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Channel Controls",
          style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.jetBlack),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: isOn ? AppColors.green : AppColors.greyShade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOn ? "Channel is ON" : "Channel is OFF",
                style: TextStyle(
                  color: isOn ? AppColors.green : AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Color(0xFF6C5CE7), size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _channelTitle ?? "",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.jetBlack),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PressablePill(
                    label: isOn ? "TURN OFF" : "TURN ON",
                    onTap: _toggling ? null : _toggleChannel,
                    loading: _toggling,
                    filled: !isOn,
                    height: 36,
                    fontSize: 12,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _controlIcon(Icons.videocam_outlined, () => _comingSoon("Going live with your webcam")),
                  _controlIcon(Icons.desktop_windows_outlined, _showExternalAppInfo),
                  _controlIcon(Icons.bar_chart_outlined, () => _comingSoon("Live stats")),
                  _controlIcon(Icons.remove_red_eye_outlined, _viewChannel),
                  _controlIcon(Icons.share_outlined, _shareChannel),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Preview",
          style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.jetBlack),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(
            isOn ? "Live stream is on, waiting for video" : "Live stream is not on air.",
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      ],
    );
  }

  Widget _controlIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: TapScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EFD9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.jetBlack),
        ),
      ),
    );
  }

  Widget _readOnlyPreview() {
    final isOn = _status?.isLive ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFD9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(
          isOn ? "Live now" : "We are not live at this moment",
          style: const TextStyle(color: AppColors.white),
        ),
      ),
    );
  }
}
