import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/contact_row.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/underline_tab_row.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/features/activity/widgets/post_card.dart';
import 'package:k54_mobile/features/groups/models/discussion_model.dart';
import 'package:k54_mobile/features/groups/models/group_model.dart';
import 'package:k54_mobile/features/groups/repositories/groups_repository.dart';
import 'package:k54_mobile/features/groups/screens/group_photos_manage_page.dart';
import 'package:k54_mobile/features/groups/screens/group_settings_page.dart';
import 'package:k54_mobile/features/members/models/member_model.dart';
import 'package:k54_mobile/features/members/repositories/members_repository.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';

/// Real group-detail screen - previously didn't exist at all, so tapping a
/// group card had nowhere real to go and the confirmed-real
/// `groups/invites` endpoint had no UI to invite anyone from. No Figma
/// reference exists for this screen (Groups' own directory/list frame is
/// the only one that's been reviewed), so this is built from the app's
/// existing visual language (same card/pill/tab patterns already used on
/// GroupsPage and ProfilePage) rather than invented decoration.
///
/// Tabs rebuilt 2026-07-22 to match the real website's own group page
/// (Members/Feed/Photos/Videos/Documents/Send Invites/Messages/
/// Discussions), per direct tester feedback + a screenshot of the live
/// site. The old dedicated "About" tab is gone - the description already
/// renders inline above the tab row (see the Column below), so a
/// separate tab for the same text was pure duplication. "Send Invites"
/// and "Messages" are action entries in the same tab row rather than
/// content tabs (same established pattern as GroupsPage's own "Create a
/// Group" tab, which triggers a dialog instead of switching content).
class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  Group? _group;
  bool _loading = true;
  Object? _error;
  bool _membershipChanged = false;

  List<Member>? _members;
  bool _membersLoading = false;

  List<Post>? _feedPosts;
  bool _feedLoading = false;

  List<PostPhoto>? _photos;
  bool _photosLoading = false;

  List<PostVideo>? _videos;
  bool _videosLoading = false;

  List<PostDocument>? _documents;
  bool _documentsLoading = false;

  List<Topic>? _topics;
  bool _topicsLoading = false;
  Object? _topicsError;

  List<GroupAlbum>? _albums;
  bool _albumsLoading = false;

  // Index into _tabLabels below - only the real content tabs (Members,
  // Feed, Photos, Videos, Albums, Documents, Discussions) ever get
  // assigned here; "Send Invites"/"Messages"/"Manage" are action taps
  // that never change this. Order matches the real site's own group page
  // exactly (confirmed live via screenshot 2026-07-22).
  int _tab = 0;

  static const _tabLabels = [
    "Members",
    "Feed",
    "Photos",
    "Videos",
    "Albums",
    "Documents",
    "Send Invites",
    "Messages",
    "Discussions",
    "Manage",
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final group = await GroupsRepository.instance.getGroup(widget.groupId);
      if (!mounted) return;
      setState(() {
        _group = group;
        _loading = false;
      });
      _loadMembers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _membersLoading = true);
    try {
      final result = await GroupsRepository.instance.getGroupMembers(widget.groupId, perPage: 50);
      if (!mounted) return;
      setState(() {
        _members = result.members;
        _membersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _membersLoading = false);
    }
  }

  Future<void> _loadFeed() async {
    setState(() => _feedLoading = true);
    try {
      final posts = await GroupsRepository.instance.getGroupActivity(widget.groupId);
      if (!mounted) return;
      setState(() {
        _feedPosts = posts;
        _feedLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _feedLoading = false);
    }
  }

  Future<void> _loadPhotos() async {
    setState(() => _photosLoading = true);
    try {
      final photos = await GroupsRepository.instance.getGroupMedia(widget.groupId);
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _photosLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _photosLoading = false);
    }
  }

  Future<void> _loadVideos() async {
    setState(() => _videosLoading = true);
    try {
      final videos = await GroupsRepository.instance.getGroupVideos(widget.groupId);
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _videosLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _videosLoading = false);
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _documentsLoading = true);
    try {
      final docs = await GroupsRepository.instance.getGroupDocuments(widget.groupId);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _documentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _documentsLoading = false);
    }
  }

  Future<void> _loadTopics() async {
    final forumId = _group?.forumId;
    if (forumId == null) return;
    setState(() {
      _topicsLoading = true;
      _topicsError = null;
    });
    try {
      final topics = await GroupsRepository.instance.getForumTopics(forumId);
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _topicsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _topicsError = e;
        _topicsLoading = false;
      });
    }
  }

  Future<void> _toggleMembership() async {
    final group = _group;
    if (group == null) return;
    final wasMember = group.isMember;
    try {
      if (wasMember) {
        await GroupsRepository.instance.leaveGroup(group.id);
      } else if (group.canJoin) {
        await GroupsRepository.instance.joinGroup(group.id);
      } else {
        await GroupsRepository.instance.requestMembership(group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Join request sent - waiting for the group admin to accept")),
          );
        }
      }
      _membershipChanged = true;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update membership: $e")),
      );
    }
  }

  Future<void> _openEditGroup(Group group) async {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);
    String privacy = group.status;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => K54Dialog(
          title: "Edit Group",
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Group Name")),
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
                onChanged: (value) => setDialogState(() => privacy = value ?? privacy),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Save")),
          ],
        ),
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty || !mounted) return;

    try {
      final updated = await GroupsRepository.instance.updateGroup(
        groupId: group.id,
        name: nameController.text.trim(),
        description: descController.text.trim(),
        status: privacy,
      );
      if (!mounted) return;
      setState(() => _group = updated);
      _membershipChanged = true;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group updated")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't update group: $e")));
    }
  }

  Future<void> _cancelRequest() async {
    final requestId = _group?.requestId;
    if (requestId == null) return;
    try {
      await GroupsRepository.instance.cancelMembershipRequest(requestId);
      _membershipChanged = true;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't cancel request: $e")),
      );
    }
  }

  /// Bulk invite picker with a shared custom message - upgraded
  /// 2026-07-23 from a one-at-a-time "tap to invite" row (direct tester
  /// feedback wanting the same bulk + custom-message experience as the
  /// Profile's Email Invites form, but for actual group membership, which
  /// that form doesn't do - it invites non-members to the whole site via
  /// `/buddyboss/v1/invites`, a different, unrelated feature from group
  /// invites). Reuses the same confirmed `sendGroupInvite` call (which
  /// already accepts a `message` param) per selected member.
  Future<void> _openInvitePicker() async {
    final group = _group;
    if (group == null) return;
    final pageContext = context;

    final searchController = TextEditingController();
    final messageController = TextEditingController();
    List<Member> results = [];
    bool searching = false;
    bool sending = false;
    String? lastQuery;
    final Set<String> selected = {};
    final Map<String, Member> selectedMembers = {};

    await showK54BottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> runSearch(String query) async {
            setSheetState(() => searching = true);
            try {
              final result = await MembersRepository.instance.getMembers(search: query, perPage: 20);
              if (lastQuery != query) return; // a newer search superseded this one
              setSheetState(() {
                results = result.members;
                searching = false;
              });
            } catch (_) {
              setSheetState(() => searching = false);
            }
          }

          Future<void> sendSelected() async {
            if (selected.isEmpty || sending) return;
            setSheetState(() => sending = true);
            final message = messageController.text.trim();
            var successCount = 0;
            Object? lastError;
            for (final userId in selected) {
              try {
                await GroupsRepository.instance.sendGroupInvite(
                  groupId: group.id,
                  userId: userId,
                  message: message,
                );
                successCount++;
              } catch (e) {
                lastError = e;
              }
            }
            if (sheetContext.mounted) Navigator.pop(sheetContext);
            if (pageContext.mounted) {
              if (successCount > 0) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(content: Text("Invited $successCount member${successCount == 1 ? '' : 's'}")),
                );
              }
              if (lastError != null) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(content: Text("Some invites failed to send: $lastError")),
                );
              }
            }
          }

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Invite to ${group.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search members...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF7F7F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (value) {
                        lastQuery = value;
                        runSearch(value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: searching
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final member = results[index];
                                final isSelected = selected.contains(member.id);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (_) => setSheetState(() {
                                    if (isSelected) {
                                      selected.remove(member.id);
                                      selectedMembers.remove(member.id);
                                    } else {
                                      selected.add(member.id);
                                      selectedMembers[member.id] = member;
                                    }
                                  }),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: AppColors.green,
                                  secondary: UserAvatar(imageUrl: member.avatarUrl, name: member.name, radius: 18),
                                  title: Text(member.name),
                                );
                              },
                            ),
                    ),
                    if (selected.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text("${selected.length} selected", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: messageController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Add a custom message (optional)",
                          filled: true,
                          fillColor: const Color(0xFFF7F7F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: PressablePill(
                          label: "Send Invites (${selected.length})",
                          onTap: sending ? null : sendSelected,
                          loading: sending,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Confirmed real 2026-07-22 (live screenshots of the site's own group
  /// page + a direct API check): a group's "Messages" tab is a real,
  /// separate feature from Discussions - a group-wide Better Messages
  /// thread every member is auto-joined to (toggled under the site's own
  /// Manage > Settings > "Group Messages"). `getGroupThreadId` maps this
  /// group to that real thread id.
  Future<void> _openMessagesTab() async {
    final group = _group;
    if (group == null) return;
    try {
      final threadId = await MessagingRepository.instance.getGroupThreadId(group.id);
      if (!mounted) return;
      if (threadId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group messages aren't enabled for this group")),
        );
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(threadId: threadId)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't open group messages: $e")));
    }
  }

  void _onTabChanged(int index) {
    if (index == 6) {
      _openInvitePicker();
      return;
    }
    if (index == 7) {
      _openMessagesTab();
      return;
    }
    if (index == 9) {
      _openManage();
      return;
    }
    setState(() => _tab = index);
    switch (index) {
      case 1:
        if (_feedPosts == null) _loadFeed();
        break;
      case 2:
        if (_photos == null) _loadPhotos();
        break;
      case 3:
        if (_videos == null) _loadVideos();
        break;
      case 4:
        if (_albums == null) _loadAlbums();
        break;
      case 5:
        if (_documents == null) _loadDocuments();
        break;
      case 8:
        if (_topics == null) _loadTopics();
        break;
    }
  }

  Future<void> _loadAlbums() async {
    setState(() => _albumsLoading = true);
    try {
      final albums = await GroupsRepository.instance.getGroupAlbums(widget.groupId);
      if (!mounted) return;
      setState(() {
        _albums = albums;
        _albumsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _albumsLoading = false);
    }
  }

  Future<void> _createAlbum() async {
    final titleController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => K54Dialog(
        title: "Create Album",
        content: TextField(controller: titleController, decoration: const InputDecoration(labelText: "Album Title")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Create")),
        ],
      ),
    );
    if (confirmed != true || titleController.text.trim().isEmpty || !mounted) return;
    try {
      await GroupsRepository.instance.createAlbum(groupId: widget.groupId, title: titleController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Album created")));
      _loadAlbums();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't create album: $e")));
    }
  }

  void _openAlbum(GroupAlbum album) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AlbumDetailPage(groupId: widget.groupId, albumId: album.id, title: album.title)),
    );
  }

  void _openManage() {
    final group = _group;
    if (group == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupManagePage(group: group)),
    ).then((changed) {
      if (changed == true) {
        _membershipChanged = true;
        _load();
      }
    });
  }

  Future<void> _createTopic() async {
    final group = _group;
    if (group == null) return;
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => K54Dialog(
        title: "New Discussion",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "What do you want to discuss?"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Post")),
        ],
      ),
    );

    if (confirmed != true || titleController.text.trim().isEmpty || !mounted) return;
    try {
      await GroupsRepository.instance.createTopic(
        groupId: group.id,
        title: titleController.text.trim(),
        content: contentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Discussion posted")));
      _loadTopics();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't post discussion: $e")));
    }
  }

  void _openTopic(Topic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicDetailPage(
          topic: topic,
          forumId: _group?.forumId ?? "",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null || _group == null) {
      return K54ErrorState(message: "Couldn't load this group.\n$_error", onRetry: _load);
    }

    final group = _group!;
    final requested = !group.isMember && group.hasPendingRequest;

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              group.coverUrl != null && group.coverUrl!.isNotEmpty
                  ? Image.network(
                      group.coverUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(height: 140, color: const Color(0xFF6A6A6A)),
                    )
                  : Container(height: 140, color: const Color(0xFF6A6A6A)),
              Positioned(
                top: 8,
                left: 8,
                child: CircleAvatar(
                  backgroundColor: AppColors.black38,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context, _membershipChanged),
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  ),
                ),
              ),
              // Real admin action - only shown when group.isAdmin is
              // true (confirmed real field, same one that now correctly
              // shows "Organizer" in the header below). Edits via the
              // confirmed `PUT groups/{id}` endpoint.
              if (group.isAdmin)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: AppColors.black38,
                    child: IconButton(
                      onPressed: () => _openEditGroup(group),
                      icon: const Icon(Icons.edit_outlined, color: AppColors.white),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                  child: UserAvatar(imageUrl: group.avatarUrl, name: group.name),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 38, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.name, style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            "${group.status} · ${group.role.isNotEmpty ? group.role : 'Group'} · ${group.totalMemberCount} members",
                            style: GoogleFonts.lato(fontSize: 12, color: AppColors.groupCardAccent),
                          ),
                        ],
                      ),
                    ),
                    PressablePill(
                      label: group.isMember ? "Joined" : (requested ? "Requested" : "Join Group"),
                      icon: group.isMember ? Icons.check : (requested ? Icons.hourglass_top : Icons.add),
                      filled: group.isMember,
                      height: 34,
                      onTap: requested ? _cancelRequest : _toggleMembership,
                    ),
                  ],
                ),
                if (group.isMember) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TapScale(
                      onTap: _openInvitePicker,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.green),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.person_add_alt, size: 16, color: AppColors.green),
                            SizedBox(width: 6),
                            Text("Invite People", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // The group's own about text - shown here, once, inline.
                // No separate "About" tab exists anymore: it used to
                // repeat this exact same text, which is why it was
                // removed (direct tester feedback).
                if (group.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(group.description, style: GoogleFonts.lato(fontSize: 13, color: AppColors.jetBlack)),
                ],
                const SizedBox(height: 16),
                UnderlineTabRow(
                  tabs: _tabLabels,
                  selectedIndex: _tab,
                  onChanged: _onTabChanged,
                ),
              ],
            ),
          ),
        ),
      ],
      body: _buildTabBody(),
    );
  }

  Widget _buildTabBody() {
    switch (_tab) {
      case 1:
        return _buildFeedTab();
      case 2:
        return _buildPhotosTab();
      case 3:
        return _buildVideosTab();
      case 4:
        return _buildAlbumsTab();
      case 5:
        return _buildDocumentsTab();
      case 8:
        return _buildDiscussionsTab();
      default:
        return _buildMembersTab();
    }
  }

  Widget _buildAlbumsTab() {
    if (_albumsLoading && _albums == null) {
      return SkeletonCardGrid(crossAxisCount: 2, count: 4);
    }
    final albums = _albums ?? [];
    return Stack(
      children: [
        if (albums.isEmpty)
          K54EmptyState(
            icon: Icons.photo_album_outlined,
            message: "No albums yet - start organizing this group's photos",
            action: PressablePill(label: "Create Album", icon: Icons.add, onTap: _createAlbum),
          )
        else
          RefreshIndicator(
            color: AppColors.green,
            onRefresh: _loadAlbums,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return FadeSlideIn(
                  key: ValueKey(album.id),
                  delay: Duration(milliseconds: 30 * index.clamp(0, 8)),
                  child: TapScale(
                    onTap: () => _openAlbum(album),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFCF8ED), Color(0xFFEFEADA)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFB4D69E)),
                        boxShadow: [
                          BoxShadow(color: AppColors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.photo_album, color: AppColors.green, size: 24),
                          ),
                          const Spacer(),
                          Text(
                            album.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            album.mediaCount == 1 ? "1 item" : "${album.mediaCount} items",
                            style: const TextStyle(fontSize: 12, color: AppColors.greyShade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: TapScale(
            onTap: _createAlbum,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.green.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.add, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersTab() {
    if (_membersLoading && _members == null) {
      return const SkeletonRowList();
    }
    final members = _members ?? [];
    if (members.isEmpty) {
      return const K54EmptyState(icon: Icons.groups_outlined, message: "No members yet");
    }
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _loadMembers,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final member = members[index];
          return FadeSlideIn(
            key: ValueKey(member.id),
            delay: Duration(milliseconds: 30 * index.clamp(0, 8)),
            child: ContactRow(
              avatarUrl: member.avatarUrl,
              title: member.name,
              onTap: () => openProfile(context, member.id),
              trailing: const Icon(Icons.chevron_right, color: AppColors.greyShade400),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_feedLoading && _feedPosts == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: 3,
        itemBuilder: (_, _) => const SkeletonPost(),
      );
    }
    final posts = _feedPosts ?? [];
    if (posts.isEmpty) {
      return K54EmptyState(
        icon: Icons.dynamic_feed_outlined,
        message: "No posts in this group yet - be the first to share something",
        action: PressablePill(label: "Refresh", icon: Icons.refresh, filled: false, onTap: _loadFeed),
      );
    }
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _loadFeed,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        itemCount: posts.length,
        itemBuilder: (context, index) => FadeSlideIn(
          key: ValueKey(posts[index].id),
          delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
          child: PostCard(
            post: posts[index],
            onPostChanged: () => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosTab() {
    if (_photosLoading && _photos == null) {
      return SkeletonCardGrid(crossAxisCount: 3, count: 9);
    }
    final photos = _photos ?? [];
    if (photos.isEmpty) {
      return const K54EmptyState(icon: Icons.photo_outlined, message: "No photos in this group yet");
    }
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _loadPhotos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: FadeSlideIn(child: PostPhotosGrid(photos: photos)),
      ),
    );
  }

  Widget _buildVideosTab() {
    if (_videosLoading && _videos == null) {
      return const SkeletonRowList(count: 3);
    }
    final videos = _videos ?? [];
    if (videos.isEmpty) {
      return const K54EmptyState(icon: Icons.videocam_outlined, message: "No videos in this group yet");
    }
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _loadVideos,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: videos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => FadeSlideIn(
          delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
          child: PostVideoPlayer(video: videos[index]),
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    if (_documentsLoading && _documents == null) {
      return const SkeletonRowList();
    }
    final docs = _documents ?? [];
    if (docs.isEmpty) {
      return const K54EmptyState(icon: Icons.description_outlined, message: "No documents in this group yet");
    }
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _loadDocuments,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: docs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => FadeSlideIn(
          delay: Duration(milliseconds: 30 * index.clamp(0, 8)),
          child: PostDocumentTile(document: docs[index]),
        ),
      ),
    );
  }

  Widget _buildDiscussionsTab() {
    final group = _group;
    if (group == null || !group.enableForum || group.forumId == null) {
      return const K54EmptyState(
        icon: Icons.forum_outlined,
        message: "Discussions aren't enabled for this group",
      );
    }
    return Stack(
      children: [
        Builder(builder: (context) {
          if (_topicsLoading && _topics == null) {
            return const SkeletonRowList();
          }
          if (_topicsError != null && _topics == null) {
            return K54ErrorState(message: "Couldn't load discussions.\n$_topicsError", onRetry: _loadTopics);
          }
          final topics = _topics ?? [];
          if (topics.isEmpty) {
            return K54EmptyState(
              icon: Icons.forum_outlined,
              message: "No discussions yet - start the conversation",
              action: PressablePill(label: "Start a Discussion", icon: Icons.add, onTap: _createTopic),
            );
          }
          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: _loadTopics,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: topics.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => FadeSlideIn(
                key: ValueKey(topics[index].id),
                delay: Duration(milliseconds: 30 * index.clamp(0, 8)),
                child: _topicTile(topics[index]),
              ),
            ),
          );
        }),
        Positioned(
          right: 16,
          bottom: 16,
          child: TapScale(
            onTap: _createTopic,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.green.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.add, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topicTile(Topic topic) {
    return TapScale(
      onTap: () => _openTopic(topic),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF8ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB4D69E)),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.forum_outlined, color: AppColors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title, style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    topic.content.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 13, color: AppColors.greyShade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.green),
                      const SizedBox(width: 4),
                      Text(
                        topic.replyCount == 1 ? "1 reply" : "${topic.replyCount} replies",
                        style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.greyShade400),
          ],
        ),
      ),
    );
  }
}

/// One discussion topic's full thread - content + replies + a composer to
/// add one, same "list + fixed composer" pattern already used by
/// CommentsSheet for post comments.
class TopicDetailPage extends StatefulWidget {
  final Topic topic;
  final String forumId;

  const TopicDetailPage({super.key, required this.topic, required this.forumId});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  List<TopicReply>? _replies;
  bool _loading = true;
  Object? _error;
  bool _sending = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final replies = await GroupsRepository.instance.getTopicReplies(widget.topic.id);
      if (!mounted) return;
      setState(() {
        _replies = replies;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await GroupsRepository.instance.createReply(
        topicId: widget.topic.id,
        forumId: widget.forumId,
        content: content,
      );
      _replyController.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't post reply: $e")));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Text(
                      widget.topic.title,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : _error != null
                      ? K54ErrorState(message: "Couldn't load replies.\n$_error", onRetry: _load)
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCF8ED),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                widget.topic.content.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                                style: GoogleFonts.lato(fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final reply in _replies ?? [])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.greyShade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    reply.content.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                                    style: GoogleFonts.lato(fontSize: 13),
                                  ),
                                ),
                              ),
                            if ((_replies ?? []).isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: Text("No replies yet - be the first to respond")),
                              ),
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: "Write a reply...",
                        filled: true,
                        fillColor: const Color(0xFFFCF8ED),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TapScale(
                    onTap: _sending ? null : _sendReply,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                            )
                          : const Icon(Icons.send, color: AppColors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One album's real photos - view + add more (same two-step
/// upload-then-attach flow as a post's own photo attachment, see
/// BuddyBossService.uploadMedia/GroupsApiService.attachMediaToAlbum).
class AlbumDetailPage extends StatefulWidget {
  final String groupId;
  final String albumId;
  final String title;

  const AlbumDetailPage({super.key, required this.groupId, required this.albumId, required this.title});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  List<PostPhoto>? _photos;
  bool _loading = true;
  Object? _error;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();
  final BuddyBossService _buddyBossService = BuddyBossService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await GroupsRepository.instance.getAlbum(widget.albumId);
      if (!mounted) return;
      setState(() {
        _photos = result.photos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _addPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _uploading = true);
    try {
      final uploadId = await _buddyBossService.uploadMedia(File(image.path));
      await GroupsRepository.instance.attachMediaToAlbum(
        groupId: widget.groupId,
        albumId: widget.albumId,
        uploadId: uploadId,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't add photo: $e")));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Text(widget.title, style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  TapScale(
                    onTap: _uploading ? null : _addPhoto,
                    child: _uploading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
                          )
                        : const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.add_a_photo_outlined, color: AppColors.green),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : _error != null
                      ? K54ErrorState(message: "Couldn't load this album.\n$_error", onRetry: _load)
                      : (_photos ?? []).isEmpty
                          ? const K54EmptyState(icon: Icons.photo_outlined, message: "No photos in this album yet")
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: PostPhotosGrid(photos: _photos!),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin group settings - covers Details, the real dynamic Group Settings
/// (privacy/invitations/upload permissions/parent group) and Forum toggle
/// (both via GroupSettingsPage, confirmed real self-describing API live
/// 2026-07-22), Photo/Cover Photo upload (GroupPhotosManagePage), Members
/// management, and Delete. "Topics" isn't a separate sub-tab here since
/// it's the same bbPress forum content already fully manageable from the
/// group's own Discussions tab. Course-linking has no confirmed real REST
/// mechanism found yet, so it's not included rather than faked.
class GroupManagePage extends StatefulWidget {
  final Group group;

  const GroupManagePage({super.key, required this.group});

  @override
  State<GroupManagePage> createState() => _GroupManagePageState();
}

class _GroupManagePageState extends State<GroupManagePage> {
  late final TextEditingController _nameController = TextEditingController(text: widget.group.name);
  late final TextEditingController _descController = TextEditingController(text: widget.group.description);
  late String _privacy = widget.group.status;
  bool _saving = false;
  bool _changed = false;

  List<Member>? _members;
  bool _membersLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _membersLoading = true);
    try {
      final result = await GroupsRepository.instance.getGroupMembers(widget.group.id, perPage: 50);
      if (!mounted) return;
      setState(() {
        _members = result.members;
        _membersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _membersLoading = false);
    }
  }

  Future<void> _saveDetails() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await GroupsRepository.instance.updateGroup(
        groupId: widget.group.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        status: _privacy,
      );
      _changed = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group updated")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't update group: $e")));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateRole(Member member, String role) async {
    try {
      await GroupsRepository.instance.updateMemberRole(groupId: widget.group.id, userId: member.id, role: role);
      _changed = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${member.name} is now a $role")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't update role: $e")));
      }
    }
  }

  Future<void> _removeMember(Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: const Text("Remove member"),
        content: Text("Remove ${member.name} from this group?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Remove", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await GroupsRepository.instance.removeMemberFromGroup(groupId: widget.group.id, userId: member.id);
      _changed = true;
      if (!mounted) return;
      setState(() => _members?.removeWhere((m) => m.id == member.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't remove member: $e")));
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: const Text("Delete group"),
        content: const Text(
          "This will permanently delete this group and everything in it. This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await GroupsRepository.instance.deleteGroup(widget.group.id);
      if (!mounted) return;
      // Pop twice - out of Manage and out of the group detail screen
      // itself, since the group it was showing no longer exists.
      Navigator.pop(context, true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't delete group: $e")));
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }

  Widget _manageLinkRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF8ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.jetBlack)),
                    Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.greyShade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.greyShade400),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, _changed),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text("Manage Group", style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle("Details"),
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Group Name")),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _privacy,
                      decoration: const InputDecoration(labelText: "Privacy"),
                      items: const [
                        DropdownMenuItem(value: "public", child: Text("Public")),
                        DropdownMenuItem(value: "private", child: Text("Private")),
                        DropdownMenuItem(value: "hidden", child: Text("Hidden")),
                      ],
                      onChanged: (value) => setState(() => _privacy = value ?? _privacy),
                    ),
                    const SizedBox(height: 12),
                    PressablePill(label: "Save Changes", onTap: _saving ? null : _saveDetails, loading: _saving),
                    const SizedBox(height: 28),

                    _sectionTitle("More Settings"),
                    _manageLinkRow(
                      icon: Icons.tune,
                      label: "Group Settings",
                      subtitle: "Privacy, invitations, uploads",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupSettingsPage(groupId: widget.group.id, nav: "group-settings", title: "Group Settings"),
                        ),
                      ),
                    ),
                    _manageLinkRow(
                      icon: Icons.forum_outlined,
                      label: "Discussion Forum",
                      subtitle: "Enable or disable the group's forum",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupSettingsPage(groupId: widget.group.id, nav: "forum", title: "Discussion Forum"),
                        ),
                      ),
                    ),
                    _manageLinkRow(
                      icon: Icons.image_outlined,
                      label: "Photo & Cover Photo",
                      subtitle: "Change the group's photo and cover",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GroupPhotosManagePage(group: widget.group)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _sectionTitle("Members"),
                    if (_membersLoading)
                      const Center(child: CircularProgressIndicator(color: AppColors.green))
                    else
                      for (final member in _members ?? [])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCF8ED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(member.name, overflow: TextOverflow.ellipsis)),
                                PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == "remove") {
                                      _removeMember(member);
                                    } else {
                                      _updateRole(member, action);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: "mod", child: Text("Promote to Moderator")),
                                    PopupMenuItem(value: "admin", child: Text("Promote to Co-organizer")),
                                    PopupMenuItem(value: "remove", child: Text("Remove from group")),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 28),
                    _sectionTitle("Delete Group"),
                    PressablePill(
                      label: "Delete Group",
                      icon: Icons.delete_outline,
                      onTap: _deleteGroup,
                      filled: false,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
