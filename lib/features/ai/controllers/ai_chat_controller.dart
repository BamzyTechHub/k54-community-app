import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/ai/models/ai_chat_message.dart';
import 'package:k54_mobile/features/ai/repositories/ai_repository.dart';

/// Drives the AI Assistant chat screen. `sending` is a distinct state
/// from a typical quick-spinner "loading" flag - the confirmed backend
/// is a single blocking call that can legitimately take up to 60 seconds
/// (a synchronous OpenAI Responses API call server-side), so the UI
/// needs a "still thinking" affordance, not just a brief spinner.
class AiChatController extends ChangeNotifier {
  final AiRepository _repo = AiRepository.instance;

  List<AiChatMessage> get messages => _repo.messages;
  bool loadingHistory = true;
  bool sending = false;
  String? error;
  bool _disposed = false;

  Future<void> load() async {
    loadingHistory = true;
    notifyListeners();
    await _repo.loadConversation();
    loadingHistory = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty || sending) return;
    sending = true;
    error = null;
    await _repo.appendUserTurn(text.trim());
    notifyListeners(); // shows the user's own message right away

    try {
      await _repo.sendPending();
    } on AiChatException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      sending = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createGroup({
    required String groupName,
    required String description,
    required String privacy,
  }) async {
    try {
      return await _repo.createGroup(
        groupName: groupName,
        description: description,
        privacy: privacy,
      );
    } catch (e) {
      error = e.toString();
      if (!_disposed) notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
