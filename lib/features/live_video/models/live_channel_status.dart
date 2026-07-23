/// A WPStream channel's real-time playback status, confirmed live
/// 2026-07-22 via the k54-live-video-bridge.php `/event-status` route
/// (which internally calls WPStream's own `wpstream_player_check_status`
/// ajax action). When [isLive] is false, [hlsUrl]/[chatUrl]/[viewsSocketUrl]
/// come back as empty strings from the real API - not a parsing failure.
class LiveChannelStatus {
  final String channelId;
  final bool isLive;
  final String hlsUrl;
  final String posterUrl;
  final String channelTitle;
  final String chatUrl;
  final String viewsSocketUrl;
  /// The real `rtmp://` ingest URL + stream key for pushing from external
  /// software (OBS, etc.) - confirmed real live 2026-07-23, same value the
  /// site's own "Go Live With External Streaming App" screen shows.
  final String broadcastUrl;
  /// The real public WPStream embed/player URL - confirmed real live
  /// 2026-07-23 (`$event_data_for_transient.embedUrl`). Only populated
  /// once the channel has actually generated event data (i.e. has been
  /// turned on at least once), same as [broadcastUrl].
  final String embedUrl;

  const LiveChannelStatus({
    required this.channelId,
    required this.isLive,
    required this.hlsUrl,
    required this.posterUrl,
    required this.channelTitle,
    required this.chatUrl,
    required this.viewsSocketUrl,
    this.broadcastUrl = '',
    this.embedUrl = '',
  });

  factory LiveChannelStatus.fromJson(Map<String, dynamic> json) {
    final transient = json[r'$event_data_for_transient'];
    final transientMap = transient is Map ? Map<String, dynamic>.from(transient) : const <String, dynamic>{};
    return LiveChannelStatus(
      channelId: (json['channel_id'] ?? '').toString(),
      isLive: (json['started'] ?? 'no').toString() == 'yes',
      hlsUrl: (json['event_uri'] ?? transientMap['hls_playback_url'] ?? '').toString(),
      posterUrl: (transientMap['poster'] ?? '').toString(),
      channelTitle: (transientMap['channel_title'] ?? '').toString(),
      chatUrl: (json['chat_url'] ?? '').toString(),
      viewsSocketUrl: (json['live_conect_views'] ?? '').toString(),
      broadcastUrl: (transientMap['broadcast_url'] ?? '').toString(),
      embedUrl: (transientMap['embedUrl'] ?? '').toString(),
    );
  }

  static const offline = LiveChannelStatus(
    channelId: '',
    isLive: false,
    hlsUrl: '',
    posterUrl: '',
    channelTitle: '',
    chatUrl: '',
    viewsSocketUrl: '',
  );
}
