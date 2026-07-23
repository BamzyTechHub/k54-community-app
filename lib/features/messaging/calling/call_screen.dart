import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/messaging/calling/call_controller.dart';

/// No Figma frame exists for a call screen (confirmed - never found in
/// any capture of this file across the whole project), so this is
/// original UI built to match the app's existing dark-surface/brand-green
/// visual language rather than a design translation. Handles both audio
/// and video calls; audio shows a centered avatar, video renders the
/// remote participant's track full-screen with the local preview as a
/// small corner tile, matching the standard calling-app convention.
class CallScreen extends StatefulWidget {
  final String threadId;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.threadId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.isVideo,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CallController(
      threadId: widget.threadId,
      otherUserName: widget.otherUserName,
      isVideo: widget.isVideo,
    );
    _controller.addListener(_onChanged);
    _controller.start();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_controller.status == CallStatus.ended || _controller.status == CallStatus.failed) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<bool> _onWillPop() async {
    await _controller.hangUp();
    return true;
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  String _statusLabel() {
    switch (_controller.status) {
      case CallStatus.connecting:
        return "Calling...";
      case CallStatus.ringing:
        return "Ringing...";
      case CallStatus.connected:
        return _formatDuration(_controller.durationSeconds);
      case CallStatus.ended:
        return "Call ended";
      case CallStatus.failed:
        return _controller.errorMessage != null ? "Couldn't connect" : "Call failed";
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Widget _remoteVideo() {
    for (final p in _controller.room.remoteParticipants.values) {
      for (final pub in p.videoTrackPublications) {
        final track = pub.track;
        if (track != null) {
          return livekit.VideoTrackRenderer(track);
        }
      }
    }
    return const SizedBox.shrink();
  }

  Widget _localVideoPreview() {
    final track = _controller.room.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track == null) return const SizedBox.shrink();
    return Positioned(
      right: 16,
      top: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 110,
          height: 150,
          child: livekit.VideoTrackRenderer(track as livekit.VideoTrack),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = _controller.status == CallStatus.connected;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onWillPop() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.jetBlack,
        body: SafeArea(
          child: Stack(
            children: [
              if (widget.isVideo && connected) Positioned.fill(child: _remoteVideo()),
              Column(
                children: [
                  const SizedBox(height: 40),
                  if (!(widget.isVideo && connected))
                    UserAvatar(
                      imageUrl: widget.otherUserAvatar,
                      name: widget.otherUserName,
                      radius: 60,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    widget.otherUserName,
                    style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusLabel(),
                    style: GoogleFonts.lato(fontSize: 15, color: AppColors.white70),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_controller.status == CallStatus.connected)
                          _controlButton(
                            icon: _controller.isMuted ? Icons.mic_off : Icons.mic,
                            filled: _controller.isMuted,
                            onTap: _controller.toggleMute,
                          ),
                        const SizedBox(width: 24),
                        _controlButton(
                          icon: Icons.call_end,
                          background: AppColors.error,
                          onTap: () => _controller.hangUp(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.isVideo && connected) _localVideoPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    Color? background,
  }) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: background ?? (filled ? AppColors.white : AppColors.white24),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: background != null || !filled ? AppColors.white : AppColors.jetBlack, size: 28),
      ),
    );
  }
}
