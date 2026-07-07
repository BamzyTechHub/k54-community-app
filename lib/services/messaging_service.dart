import '../models/chat_model.dart';
import '../models/message_thread_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MessagingService {
  final ApiService _api = ApiService.instance;
  final AuthService _authService = AuthService();

  String? _cachedUserId;

  Future<String> _currentUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final response = await _authService.getCurrentUser();
    _cachedUserId = (response.data['id'] ?? '').toString();
    return _cachedUserId!;
  }

  /// Inbox list.
  Future<List<MessageThread>> getThreads() async {
    final userId = await _currentUserId();
    final response = await _api.get(
      "/buddyboss/v1/messages",
      query: {
        "box": "inbox",
        "user_id": userId,
        "per_page": 50,
      },
    );

    final List data = response.data is List
        ? response.data
        : (response.data['threads'] ?? response.data['data'] ?? []);

    return data
        .map((t) => MessageThread.fromJson(
              t as Map<String, dynamic>,
              currentUserId: userId,
            ))
        .toList();
  }

  /// Full thread with all messages.
  Future<MessageThread> getThread(String threadId) async {
    final userId = await _currentUserId();
    final response = await _api.get("/buddyboss/v1/messages/$threadId");
    return MessageThread.fromJson(
      response.data as Map<String, dynamic>,
      currentUserId: userId,
    );
  }

  /// Reply to an existing thread.
  Future<ChatMessage> sendReply({
    required String threadId,
    required String message,
  }) async {
    final userId = await _currentUserId();
    final response = await _api.post("/buddyboss/v1/messages", {
      "id": threadId,
      "message": message,
    });

    // The API returns the whole updated thread; the newest message is last.
    final thread = MessageThread.fromJson(
      response.data as Map<String, dynamic>,
      currentUserId: userId,
    );
    if (thread.messages.isNotEmpty) return thread.messages.last;

    // Fallback: build a local optimistic message if the response shape
    // doesn't include the messages list.
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: userId,
      senderName: "You",
      message: message,
      date: DateTime.now(),
      isMe: true,
    );
  }

  /// Starts a brand-new thread with a recipient (used from a member's
  /// profile page, not from the inbox screen).
  Future<MessageThread> startThread({
    required String recipientId,
    required String message,
  }) async {
    final userId = await _currentUserId();
    final response = await _api.post("/buddyboss/v1/messages", {
      "message": message,
      "recipients": [recipientId],
    });
    return MessageThread.fromJson(
      response.data as Map<String, dynamic>,
      currentUserId: userId,
    );
  }
}