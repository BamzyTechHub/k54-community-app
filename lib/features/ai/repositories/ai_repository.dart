import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:k54_mobile/features/ai/models/ai_chat_message.dart';
import 'package:k54_mobile/features/ai/services/ai_api_service.dart';

/// Thrown when /chat returns one of the two known error phrases in its
/// `reply` field. There's no structured error/status code from the
/// backend at all (confirmed - always HTTP 200), so this is the only
/// way to detect a failure; see AiApiService.chat's doc comment.
class AiChatException implements Exception {
  final String message;
  AiChatException(this.message);
  @override
  String toString() => message;
}

/// Owns the local conversation - the backend has no server-side history
/// at all, so this is the single source of truth the app itself must
/// maintain and resend on every call (confirmed in
/// docs/api-audit/ai-assistant.md). Persisted via shared_preferences so
/// a conversation survives an app restart, since nothing server-side
/// will ever remember it.
class AiRepository {
  AiRepository._internal();
  static final AiRepository instance = AiRepository._internal();

  static const _storageKey = "k54_ai_conversation";
  static const _maxHistoryTurns = 10;

  static const _connectionErrorText = "K54 AI connection error.";
  static const _emptyReplyErrorText = "K54 AI could not generate a response.";

  final AiApiService _api = AiApiService();
  List<AiChatMessage> _messages = [];
  bool _loaded = false;

  /// Current in-memory conversation. Populated after [loadConversation]
  /// resolves at least once; empty before that.
  List<AiChatMessage> get messages => List.unmodifiable(_messages);

  Future<List<AiChatMessage>> loadConversation() async {
    if (_loaded) return _messages;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        _messages = decoded
            .map((m) => AiChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      } catch (_) {
        _messages = [];
      }
    }
    _loaded = true;
    return _messages;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_messages.map((m) => m.toJson()).toList()));
  }

  Future<void> clearConversation() async {
    _messages = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Appends [text] as a user turn immediately (before the network call)
  /// so the UI can show it right away rather than waiting for a reply
  /// that can legitimately take up to 60 seconds - call this first, then
  /// [sendPending] to actually contact the backend.
  Future<void> appendUserTurn(String text) async {
    _messages.add(AiChatMessage(role: "user", content: text, timestamp: DateTime.now()));
    await _persist();
  }

  /// Sends the most recently appended user turn to the backend and
  /// appends the assistant's reply to local history. Throws
  /// [AiChatException] if the backend's reply matches one of its two
  /// known error phrases - the message itself is NOT added to history as
  /// a real assistant turn in that case, since it's an error state, not
  /// real conversation content.
  Future<AiChatMessage> sendPending() async {
    final text = _messages.last.content;
    final history = _messages
        .take(_messages.length - 1) // exclude the just-added user turn
        .toList()
        .reversed
        .take(_maxHistoryTurns)
        .toList()
        .reversed
        .map((m) => {"role": m.role, "content": m.content})
        .toList();

    try {
      final response = await _api.chat(message: text, history: history);
      final reply = (response.data["reply"] ?? "").toString();

      if (reply == _connectionErrorText || reply == _emptyReplyErrorText || reply.isEmpty) {
        throw AiChatException(reply.isEmpty ? _emptyReplyErrorText : reply);
      }

      final assistantMessage =
          AiChatMessage(role: "assistant", content: reply, timestamp: DateTime.now());
      _messages.add(assistantMessage);
      await _persist();
      return assistantMessage;
    } on AiChatException {
      rethrow;
    } catch (e) {
      throw AiChatException("Couldn't reach K54 AI: $e");
    }
  }

  Future<Map<String, dynamic>> createGroup({
    required String groupName,
    required String description,
    required String privacy,
  }) async {
    final response = await _api.createGroup(
      groupName: groupName,
      description: description,
      privacy: privacy,
    );
    return Map<String, dynamic>.from(response.data);
  }
}
