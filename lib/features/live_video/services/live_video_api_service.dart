import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Raw calls to the custom `k54-live/v1` REST namespace registered by
/// docs/api-audit/k54-live-video-bridge.php (a Code Snippets snippet on the
/// live site, not part of any stock WordPress/BuddyBoss/WPStream REST
/// surface) - see that file's header comment for why this bridge exists
/// (WPStream's own live-status logic only lives behind admin-ajax.php
/// actions that trust a browser cookie session, which this app's JWT auth
/// can never satisfy directly).
class LiveVideoApiService {
  final ApiService _api = ApiService.instance;

  /// Confirmed live 2026-07-22: resolves a user id to their own
  /// `wpstream_product` channel post id, or null if they don't have one.
  Future<Response> getChannelForUser(String userId) {
    return _api.get("/k54-live/v1/channel-for-user", query: {"user_id": userId});
  }

  /// Confirmed live 2026-07-22: the real playback payload (started/HLS
  /// url/poster/chat_url/etc.) for a given channel id, via WPStream's own
  /// `wpstream_player_check_status` ajax action.
  Future<Response> getEventStatus(String channelId) {
    return _api.get("/k54-live/v1/event-status", query: {"channel_id": channelId});
  }

  /// Confirmed live 2026-07-23 via a captured real "TURN ON" click plus a
  /// live before/after test - this is what actually activates a channel
  /// (not just fetching its broadcast URL, which alone doesn't turn it on).
  Future<Response> turnOnChannel(String channelId) {
    return _api.post("/k54-live/v1/turn-on-channel", {"show_id": channelId});
  }

  /// Confirmed live 2026-07-23 via a captured real "TURN OFF" click and a
  /// live before/after test on the real site.
  Future<Response> turnOffChannel(String channelId) {
    return _api.post("/k54-live/v1/turn-off-channel", {"show_id": channelId});
  }
}
