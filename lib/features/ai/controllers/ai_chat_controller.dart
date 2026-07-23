import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/ai/models/ai_chat_message.dart';
import 'package:k54_mobile/features/ai/repositories/ai_repository.dart';

/// Steps of the in-chat, scripted group-creation Q&A - matches the real
/// website's own onboarding wizard exactly (confirmed from its live JS,
/// 2026-07-21: `onboardingState`/`onboardingData`/`handleOnboarding()` in
/// the site's own `<script>`, not guessed). This is entirely client-side
/// orchestration - the real `/k54-ai/v1/chat` backend has no function-
/// calling or group-creation awareness at all, and `/create-group` only
/// reads `groupName`/`description`/`privacy` out of a richer request body
/// the website also sends (`type`/`topics`/`forum`/`courseTab`/
/// `inviteMembers` - collected and shown back in the review step, same
/// as the website, even though the backend currently ignores them). The
/// real site does NOT validate Privacy/Topics/Forum/CourseTab/Invites
/// answers at all - it stores whatever text was typed verbatim and moves
/// on; the only gate is the final review step, which requires literally
/// typing "CREATE" to proceed (case-insensitive) and re-prompts
/// otherwise. Matched here rather than the earlier, stricter version
/// this app briefly had (which validated Privacy and skipped the name
/// question when triggered from a quick-action pill - neither of which
/// matches the real site's behavior).
enum _GroupStep { name, description, privacy, topics, forum, courseTab, inviteMembers, review }

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

  _GroupStep? _groupStep;
  String _groupType = "Other";
  String _groupName = "";
  String _groupDescription = "";
  String _groupPrivacy = "";
  String _groupTopics = "";
  String _groupForum = "";
  String _groupCourseTab = "";
  String _groupInviteMembers = "";

  bool get isCreatingGroup => _groupStep != null;

  static final RegExp _groupIntentPattern = RegExp(
    r'\b(create|make|start|set ?up)\b.{0,15}\bgroup\b',
    caseSensitive: false,
  );

  Future<void> load() async {
    loadingHistory = true;
    notifyListeners();
    await _repo.loadConversation();
    loadingHistory = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || sending) return;

    if (_groupStep != null) {
      await _handleGroupAnswer(trimmed);
      return;
    }

    if (_groupIntentPattern.hasMatch(trimmed)) {
      await _repo.appendUserTurn(trimmed);
      notifyListeners();
      await startGroupCreation();
      return;
    }

    sending = true;
    error = null;
    await _repo.appendUserTurn(trimmed);
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

  /// Starts the scripted Q&A. [type] comes from the quick-action pills
  /// ("Create Church Group" etc., matching the real site's "Church"/
  /// "NGO"/"Study Group" `type` values) - it only customizes the
  /// question wording, it does NOT pre-fill or skip the name question:
  /// the real site always asks "What would you like to name your
  /// ${type}?" fresh, even when a quick action started the flow.
  Future<void> startGroupCreation({String type = "Other"}) async {
    _groupType = type;
    _groupName = "";
    _groupDescription = "";
    _groupPrivacy = "";
    _groupTopics = "";
    _groupForum = "";
    _groupCourseTab = "";
    _groupInviteMembers = "";
    _groupStep = _GroupStep.name;

    final label = type == "Other" ? "group" : type;
    await _repo.appendAssistantScripted(
      "Great. Let's create your $label step-by-step.\n\nWhat would you like to name your $label?",
    );
    if (!_disposed) notifyListeners();
  }

  Future<void> _handleGroupAnswer(String answer) async {
    await _repo.appendUserTurn(answer);
    notifyListeners();

    switch (_groupStep!) {
      case _GroupStep.name:
        _groupName = answer;
        _groupStep = _GroupStep.description;
        await _repo.appendAssistantScripted(
          "Describe the purpose or mission of your organization/group.",
        );
        break;

      case _GroupStep.description:
        _groupDescription = answer;
        _groupStep = _GroupStep.privacy;
        await _repo.appendAssistantScripted(
          "Should this group be:\n\n• Public\n• Private\n• Hidden",
        );
        break;

      case _GroupStep.privacy:
        // The real site doesn't validate this at all - whatever is typed
        // is stored verbatim and sent as-is (the backend itself lowercases
        // and only recognizes exact "private"/"hidden", defaulting
        // anything else to "public" - see AiApiService.createGroup).
        _groupPrivacy = answer;
        _groupStep = _GroupStep.topics;
        await _repo.appendAssistantScripted("Would you like to enable Topics?\n\n• Yes\n• No");
        break;

      case _GroupStep.topics:
        _groupTopics = answer;
        _groupStep = _GroupStep.forum;
        await _repo.appendAssistantScripted("Would you like to enable Forums?\n\n• Yes\n• No");
        break;

      case _GroupStep.forum:
        _groupForum = answer;
        _groupStep = _GroupStep.courseTab;
        await _repo.appendAssistantScripted(
          "Would you like to add a Course Tab?\n\nCourses can be created later.\n\n• Yes\n• No",
        );
        break;

      case _GroupStep.courseTab:
        _groupCourseTab = answer;
        _groupStep = _GroupStep.inviteMembers;
        await _repo.appendAssistantScripted(
          "Would you like to invite members now?\n\n• Invite Now\n• Later",
        );
        break;

      case _GroupStep.inviteMembers:
        _groupInviteMembers = answer;
        _groupStep = _GroupStep.review;
        await _repo.appendAssistantScripted(
          "Review Your Setup\n\n"
          "Type: $_groupType\n\n"
          "Group Name:\n$_groupName\n\n"
          "Description:\n$_groupDescription\n\n"
          "Privacy:\n$_groupPrivacy\n\n"
          "Topics:\n$_groupTopics\n\n"
          "Forum:\n$_groupForum\n\n"
          "Course Tab:\n$_groupCourseTab\n\n"
          "Invites:\n$_groupInviteMembers\n\n"
          "Type CREATE to continue.",
        );
        break;

      case _GroupStep.review:
        if (answer.trim().toUpperCase() != "CREATE") {
          await _repo.appendAssistantScripted("Please type CREATE to continue.");
          break;
        }
        await _createGroupFromSession();
        break;
    }

    if (!_disposed) notifyListeners();
  }

  Future<void> _createGroupFromSession() async {
    final name = _groupName;

    await _repo.appendAssistantScripted("Creating your group \"$name\" now...");
    if (!_disposed) notifyListeners();

    try {
      final result = await _repo.createGroup(
        groupName: name,
        description: _groupDescription,
        privacy: _groupPrivacy,
        type: _groupType,
        topics: _groupTopics,
        forum: _groupForum,
        courseTab: _groupCourseTab,
        inviteMembers: _groupInviteMembers,
      );
      if (result["success"] == true) {
        final groupId = result["group_id"]?.toString();
        await _repo.appendAssistantScripted(
          "✅ Group created successfully.\n\nTap below to view it.",
          createdGroupId: groupId,
        );
      } else {
        await _repo.appendAssistantScripted(
          "❌ Group creation failed.\n\n${result["message"] ?? "unknown error"}",
        );
      }
    } catch (_) {
      await _repo.appendAssistantScripted("❌ Connection error while creating group.");
    } finally {
      _groupStep = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
