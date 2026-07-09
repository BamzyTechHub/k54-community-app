import 'dart:async';
import 'package:flutter/material.dart';

import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';

class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key});

  @override
  State<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<NewConversationPage> {
  final MessagingRepository _repo = MessagingRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  String? _startingMemberId; // shows a spinner on the row being opened

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await _repo.searchMembers(query.trim());
      if (!mounted) return;
      setState(() {
        _results = members;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openOrStartThread(Map<String, dynamic> member) async {
    final memberId = (member['id'] ?? '').toString();
    if (memberId.isEmpty) return;

    setState(() => _startingMemberId = memberId);
    try {
      // findOrCreateThreadWith checks the cached inbox first, so tapping
      // a member you already have a thread with opens it instead of
      // creating a duplicate.
      final thread = await _repo.findOrCreateThreadWith(otherUserId: memberId);
      if (!mounted) return;
      // pushReplacement completes the *original* push (awaited by
      // MessagesPage) immediately with `result` - it does not wait for
      // ChatPage to later be popped. Passing `result: true` here is what
      // actually triggers MessagesPage's inbox refresh; the previous code
      // awaited this call and tried to pop afterwards, which never ran
      // (this page's State is already disposed by the time pushReplacement
      // itself would resolve).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(threadId: thread.id, thread: thread)),
        result: true,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't start conversation: $e")));
    } finally {
      if (mounted) setState(() => _startingMemberId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Text("New Message",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFD9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "You can reopen an existing conversation with a friend "
                  "here. Starting a brand-new conversation isn't available "
                  "yet - it's coming in a future update.",
                  style: TextStyle(fontSize: 12.5, height: 1.3),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: "Search your friends...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text("Search failed: $_error"));
    }
    if (_searchController.text.trim().isEmpty) {
      return const Center(child: Text("Search for a friend to message"));
    }
    if (_results.isEmpty) {
      return const Center(child: Text("No friends found"));
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = _results[index] as Map<String, dynamic>;
        final id = (member['id'] ?? '').toString();
        final name = (member['name'] ?? 'Unknown').toString();
        final avatar = member['avatar_urls']?['thumb']?.toString();
        final isStarting = _startingMemberId == id;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?")
                : null,
          ),
          title: Text(name),
          trailing: isStarting
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : null,
          onTap: isStarting ? null : () => _openOrStartThread(member),
        );
      },
    );
  }
}
