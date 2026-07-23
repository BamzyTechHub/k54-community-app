import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/ai/controllers/ai_chat_controller.dart';
import 'package:k54_mobile/features/ai/models/ai_chat_message.dart';
import 'package:k54_mobile/features/groups/screens/group_detail_page.dart';
import 'package:k54_mobile/features/search/screens/search_results_page.dart';

/// Matches the K54 Figma file's AI Assistant screen exactly (node
/// 118:22, rendered 2026-07-08): header with search, a chat area, an
/// input bar, quick-action pills, and a "Quick Searches" section.
///
/// Fully rebuilt (the previous 498-line version had zero backend wiring
/// - send was a print() stub) against the confirmed `/k54-ai/v1/chat`
/// and `/k54-ai/v1/create-group` endpoints (see
/// docs/api-audit/ai-assistant.md, sourced directly from the PHP
/// backend, not inferred).
///
/// Group creation ("Create NGO Community" etc.) is a real, scripted
/// in-chat Q&A now (name -> privacy -> description -> auto-create),
/// not a popup form - the real backend has no conversational/function-
/// calling awareness of group creation at all, so this sequencing is
/// entirely client-side (see AiChatController's doc comment).
class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final AiChatController _controller = AiChatController();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.load();
  }

  void _onControllerChanged() {
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? presetText]) async {
    final text = presetText ?? _inputController.text;
    if (text.trim().isEmpty || _controller.sending) return;
    _inputController.clear();
    await _controller.send(text);
  }

  void _openGroup(String groupId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailPage(groupId: groupId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  // No back arrow - this is a main bottom-nav destination
                  // (like Home/Members/Groups/Courses), not a pushed
                  // screen, and the real header (confirmed against a
                  // fresh screenshot 2026-07-18) doesn't show one.
                  Text(
                    "AI Assistant",
                    style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  // Was purely decorative (no onTap at all) - now real,
                  // matching how every other screen's search pill/icon
                  // behaves (Home, Messages, Groups, Members).
                  TapScale(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchResultsPage()),
                    ),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      // Was 140x32 - noticeably smaller than every other
                      // screen's search affordance in the app (flagged
                      // directly: "the search bar looks very tiny").
                      width: 170,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      // #FCF8ED - same systemic fix as K54SearchField (was
                      // the stale tan/gold groupCardBackground).
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCF8ED),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 18, color: AppColors.jetBlack),
                          const SizedBox(width: 8),
                          Text("Search", style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_controller.messages.isEmpty && !_controller.sending)
                Text(
                  "Chat with K54 AI to get help navigating the platform, courses, and community.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 14, color: AppColors.greyShade700),
                ),
              const SizedBox(height: 12),
              Expanded(child: _buildChatArea()),
              const SizedBox(height: 12),
              _buildInputBar(),
              const SizedBox(height: 14),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const K54BottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildChatArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.groupCardAccent),
      ),
      child: _controller.loadingHistory
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : _controller.messages.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(15),
                  itemCount: _controller.messages.length + (_controller.sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _controller.messages.length) {
                      return _buildThinkingBubble();
                    }
                    final message = _controller.messages[index];
                    return FadeSlideIn(
                      key: ValueKey("${message.isUser}-${message.content.hashCode}-$index"),
                      child: _buildBubble(message),
                    );
                  },
                ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          // Same received-bubble color as chat_page.dart (Messages) -
          // was a different, inconsistent groupCardBackground shade
          // before, so the two "chat with someone" screens in this app
          // didn't visually read as the same pattern.
          color: const Color(0xFFFCF8ED),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
            ),
            const SizedBox(width: 10),
            Text(
              "K54 AI is thinking - this can take up to a minute...",
              style: GoogleFonts.lato(fontSize: 13, color: AppColors.greyShade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(AiChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            // Matches chat_page.dart's real "sent" bubble exactly (same
            // color + same asymmetric corner shape) instead of a brand
            // gradient no other chat-style screen in the app uses.
            color: const Color(0xFFB4D69E),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
          ),
          child: Text(
            message.content,
            style: GoogleFonts.lato(color: AppColors.white, fontSize: 14),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF8ED),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MarkdownBody(
              data: message.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack),
                h1: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                h2: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
                h3: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.bold),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.white,
                  border: const Border(left: BorderSide(color: AppColors.green, width: 3)),
                ),
                a: const TextStyle(color: AppColors.green, decoration: TextDecoration.underline),
              ),
            ),
            // Real "View Group" action - only present on the one scripted
            // confirmation message that follows a successful in-chat
            // group creation (see AiChatMessage.createdGroupId's doc
            // comment).
            if (message.createdGroupId != null) ...[
              const SizedBox(height: 8),
              TapScale(
                onTap: () => _openGroup(message.createdGroupId!),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.groups, size: 16, color: AppColors.white),
                      SizedBox(width: 6),
                      Text("View Group", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    // Same shape/press-feedback pattern as chat_page.dart's input bar
    // (Messages) - the attach icon and the send button were plain
    // IconButtons with no press animation at all, the one static-feeling
    // part of an otherwise animated screen.
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      // Exact colors from the AI ASSISTANT Figma frame (node 118:22,
      // "Typing" input bar), pulled via the REST API 2026-07-16 - was a
      // muted gray-green pair before this measurement existed.
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFB4D69E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: "Ask K54 AI Anything...",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          TapScale(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Attachments are coming soon")),
            ),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.attach_file, color: AppColors.grey),
            ),
          ),
          const SizedBox(width: 4),
          TapScale(
            onTap: (_controller.sending || _inputController.text.trim().isEmpty) ? null : () => _send(),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
              child: Center(
                child: _controller.sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.send, color: AppColors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillPairRow(String leftLabel, VoidCallback onLeftTap, String rightLabel, VoidCallback onRightTap) {
    // Explicit 2-column pairing (not a Wrap, which let pill widths and
    // wrapping drift from row to row) - matches the Figma screenshot's
    // clean, equal-width two-column grid exactly.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: PressablePill(label: leftLabel, onTap: onLeftTap, height: 42, fontSize: 11)),
          const SizedBox(width: 10),
          Expanded(child: PressablePill(label: rightLabel, onTap: onRightTap, height: 42, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _pillPairRow(
          "Create First Course", () => _send("Help me create my first course"),
          "Create NGO Community", () => _controller.startGroupCreation(type: "NGO"),
        ),
        _pillPairRow(
          "Create Church Group", () => _controller.startGroupCreation(type: "Church"),
          "Start Study Group", () => _controller.startGroupCreation(type: "Study Group"),
        ),
        const SizedBox(height: 6),
        Text("Quick Searches", style: GoogleFonts.lato(fontSize: 14, color: AppColors.greyShade700)),
        const SizedBox(height: 10),
        _pillPairRow(
          "Grow My Business", () => _send("Help me grow my business"),
          "Scale My Result", () => _send("Help me scale my results"),
        ),
      ],
    );
  }
}
