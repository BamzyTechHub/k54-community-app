import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import '../messaging/repositories/messaging_repository.dart';
import '../messaging/screens/chat_page.dart';

class ProfileActions extends StatefulWidget {
  final bool isCurrentUser;
  final String? otherUserId;

  const ProfileActions({
    super.key,
    required this.isCurrentUser,
    this.otherUserId,
  });

  @override
  State<ProfileActions> createState() => _ProfileActionsState();
}

class _ProfileActionsState extends State<ProfileActions> {
  bool _openingChat = false;

  Future<void> _openMessage() async {
    final otherUserId = widget.otherUserId;
    if (otherUserId == null || _openingChat) return;

    setState(() => _openingChat = true);
    try {
      // findOrCreateThreadWith opens the existing thread if one is
      // already cached, otherwise starts a new one — never duplicates.
      final thread = await MessagingRepository.instance
          .findOrCreateThreadWith(otherUserId: otherUserId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(threadId: thread.id, thread: thread),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't open chat: $e")));
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF008000), width: 1.5),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF008000), Color(0xFFAB8000), Color(0xFF008000)],
              ),
            ),
            child: const Center(
              child: Text("Follow", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _openingChat ? null : _openMessage,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF008000), width: 1.5),
              ),
              child: Center(
                child: _openingChat
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF008000)),
                          SizedBox(width: 8),
                          Text(
                            "Message",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008000)),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}