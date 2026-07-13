import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/nav.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/features/ai/controllers/ai_chat_controller.dart';
import 'package:k54_mobile/features/ai/models/ai_chat_message.dart';

/// Matches the K54 Figma file's AI Assistant screen exactly (node
/// 118:22, rendered 2026-07-08): header with search, a chat area, an
/// input bar, quick-action pills, and a "Quick Searches" section.
///
/// Fully rebuilt (the previous 498-line version had zero backend wiring
/// - send was a print() stub) against the confirmed `/k54-ai/v1/chat`
/// and `/k54-ai/v1/create-group` endpoints (see
/// docs/api-audit/ai-assistant.md, sourced directly from the PHP
/// backend, not inferred).
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

  Future<void> _startGroupCreation(String defaultName) async {
    final nameController = TextEditingController(text: defaultName);
    final descController = TextEditingController();
    String privacy = "public";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text("Create Group"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Group Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: privacy,
                decoration: const InputDecoration(labelText: "Privacy"),
                items: const [
                  DropdownMenuItem(value: "public", child: Text("Public")),
                  DropdownMenuItem(value: "private", child: Text("Private")),
                  DropdownMenuItem(value: "hidden", child: Text("Hidden")),
                ],
                onChanged: (value) => setDialogState(() => privacy = value ?? "public"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    if (nameController.text.trim().isEmpty) return;

    final result = await _controller.createGroup(
      groupName: nameController.text.trim(),
      description: descController.text.trim(),
      privacy: privacy,
    );

    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't create group: ${_controller.error}")),
      );
      return;
    }
    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Group created successfully.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Group creation failed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => goHome(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    "AI Assistant",
                    style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Container(
                    width: 140,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.groupCardBackground,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 16, color: AppColors.jetBlack),
                        const SizedBox(width: 6),
                        Text("Search", style: GoogleFonts.lato(fontSize: 12, color: AppColors.jetBlack)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_controller.messages.isEmpty && !_controller.sending)
                Text(
                  "Chat with K54 AI to get help navigating the platform, courses, and community.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade700),
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
          ? const Center(child: CircularProgressIndicator())
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
                    return _buildBubble(_controller.messages[index]);
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
          color: AppColors.groupCardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              "K54 AI is thinking - this can take up to a minute...",
              style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade700),
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
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: GoogleFonts.lato(color: Colors.white, fontSize: 14),
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
          color: AppColors.groupCardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: MarkdownBody(
          data: message.content,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack),
            h1: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
            h2: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
            h3: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.bold),
            blockquoteDecoration: BoxDecoration(
              color: Colors.white,
              border: const Border(left: BorderSide(color: AppColors.green, width: 3)),
            ),
            a: const TextStyle(color: AppColors.green, decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFD9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: "Ask K54 AI Anything...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Attachments are coming soon")),
            ),
            icon: const Icon(Icons.attach_file, color: Colors.grey),
          ),
          IconButton(
            onPressed: _controller.sending ? null : () => _send(),
            icon: _controller.sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send, color: AppColors.green),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 10),
      child: PressablePill(label: label, onTap: onTap, height: 42),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            _pill("Create First Course", () => _send("Help me create my first course")),
            _pill("Create NGO Community", () => _startGroupCreation("NGO Community")),
            _pill("Create Church Group", () => _startGroupCreation("Church Group")),
            _pill("Start Study Group", () => _startGroupCreation("Study Group")),
          ],
        ),
        const SizedBox(height: 6),
        Text("Quick Searches", style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            _pill("Grow My Business", () => _send("Help me grow my business")),
            _pill("Scale My Result", () => _send("Help me scale my results")),
          ],
        ),
      ],
    );
  }
}
