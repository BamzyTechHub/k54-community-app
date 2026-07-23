import 'package:k54_mobile/features/live_video/models/live_channel_status.dart';
import 'package:k54_mobile/features/live_video/services/live_video_api_service.dart';

class LiveVideoRepository {
  LiveVideoRepository._internal();
  static final LiveVideoRepository instance = LiveVideoRepository._internal();

  final LiveVideoApiService _api = LiveVideoApiService();

  Future<String?> getChannelIdForUser(String userId) async {
    final response = await _api.getChannelForUser(userId);
    final data = Map<String, dynamic>.from(response.data);
    return data['channel_id']?.toString();
  }

  Future<LiveChannelStatus> getEventStatus(String channelId) async {
    final response = await _api.getEventStatus(channelId);
    final data = Map<String, dynamic>.from(response.data);
    return LiveChannelStatus.fromJson(data);
  }

  /// Convenience combining both calls - resolves [userId]'s channel, then
  /// fetches its live status. Returns [LiveChannelStatus.offline] if the
  /// user has no channel at all (rather than throwing), since that's a
  /// real, valid outcome (not every user has gone live before).
  Future<LiveChannelStatus> getStatusForUser(String userId) async {
    final channelId = await getChannelIdForUser(userId);
    if (channelId == null) return LiveChannelStatus.offline;
    return getEventStatus(channelId);
  }

  Future<void> turnOnChannel(String channelId) => _api.turnOnChannel(channelId);

  Future<void> turnOffChannel(String channelId) => _api.turnOffChannel(channelId);
}
