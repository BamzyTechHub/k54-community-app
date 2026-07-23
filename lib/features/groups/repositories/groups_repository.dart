import 'dart:io';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/features/groups/models/discussion_model.dart';
import 'package:k54_mobile/features/groups/models/group_model.dart';
import 'package:k54_mobile/features/groups/models/group_setting_model.dart';
import 'package:k54_mobile/features/groups/services/groups_api_service.dart';
import 'package:k54_mobile/features/members/models/member_model.dart';

class GroupsRepository {
  GroupsRepository._internal();
  static final GroupsRepository instance = GroupsRepository._internal();

  final GroupsApiService _api = GroupsApiService();
  final AuthService _authService = AuthService();

  String? _cachedUserId;

  Future<String> currentUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final response = await _authService.getCurrentUser();
    _cachedUserId = (response.data['id'] ?? '').toString();
    return _cachedUserId!;
  }

  List<Group> _parseGroups(dynamic data) {
    final List raw = data is List ? data : const [];
    return raw.whereType<Map>().map((g) => Group.fromBuddyBoss(Map<String, dynamic>.from(g))).toList();
  }

  /// [total] comes from WordPress REST's standard `X-WP-Total` header.
  Future<({List<Group> groups, int? total})> getGroups({
    String? search,
    String? orderby,
    String? order,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _api.getGroups(
      search: search,
      orderby: orderby,
      order: order,
      page: page,
      perPage: perPage,
    );
    final totalHeader = response.headers.value("x-wp-total");
    return (
      groups: _parseGroups(response.data),
      total: totalHeader != null ? int.tryParse(totalHeader) : null,
    );
  }

  Future<List<Group>> getMyGroups() async {
    final userId = await currentUserId();
    final response = await _api.getMyGroups(userId: userId);
    return _parseGroups(response.data);
  }

  Future<Group> createGroup({
    required String name,
    required String description,
    required String status,
  }) async {
    final response = await _api.createGroup(name: name, description: description, status: status);
    return Group.fromBuddyBoss(Map<String, dynamic>.from(response.data));
  }

  Future<void> joinGroup(String groupId) async {
    final userId = await currentUserId();
    await _api.joinGroup(groupId: groupId, userId: userId);
  }

  Future<void> leaveGroup(String groupId) async {
    final userId = await currentUserId();
    await _api.leaveGroup(groupId: groupId, userId: userId);
  }

  /// The real join flow for a private group - see
  /// GroupsApiService.requestMembership's doc comment.
  Future<void> requestMembership(String groupId) async {
    final userId = await currentUserId();
    await _api.requestMembership(groupId: groupId, userId: userId);
  }

  Future<void> cancelMembershipRequest(String requestId) {
    return _api.cancelMembershipRequest(requestId);
  }

  Future<Group> updateGroup({
    required String groupId,
    required String name,
    required String description,
    required String status,
  }) async {
    final response = await _api.updateGroup(groupId: groupId, name: name, description: description, status: status);
    return Group.fromBuddyBoss(Map<String, dynamic>.from(response.data));
  }

  Future<Group> getGroup(String groupId) async {
    final response = await _api.getGroup(groupId);
    return Group.fromBuddyBoss(Map<String, dynamic>.from(response.data));
  }

  Future<({List<Member> members, int? total})> getGroupMembers(String groupId, {int page = 1, int perPage = 20}) async {
    final response = await _api.getGroupMembers(groupId: groupId, page: page, perPage: perPage);
    final List raw = response.data is List ? response.data : const [];
    final members = raw.whereType<Map>().map((m) => Member.fromBuddyBoss(Map<String, dynamic>.from(m))).toList();
    final totalHeader = response.headers.value("x-wp-total");
    return (members: members, total: totalHeader != null ? int.tryParse(totalHeader) : null);
  }

  /// See GroupsApiService.sendGroupInvite's doc comment - real endpoint,
  /// request shape confirmed from the route index's arg schema, not yet
  /// exercised live (sending a real invite would notify a real other
  /// person, which isn't something to fire just to test a shape).
  Future<void> sendGroupInvite({required String groupId, required String userId, String message = ""}) async {
    final inviterId = await currentUserId();
    await _api.sendGroupInvite(groupId: groupId, userId: userId, inviterId: inviterId, message: message);
  }

  Future<List<Post>> getGroupActivity(String groupId, {int page = 1}) async {
    final response = await _api.getGroupActivity(groupId: groupId, page: page);
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((p) => Post.fromBuddyBoss(Map<String, dynamic>.from(p))).toList();
  }

  Future<List<PostPhoto>> getGroupMedia(String groupId, {int page = 1}) async {
    final response = await _api.getGroupMedia(groupId: groupId, page: page);
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((m) => PostPhoto.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  Future<List<PostVideo>> getGroupVideos(String groupId, {int page = 1}) async {
    final response = await _api.getGroupVideos(groupId: groupId, page: page);
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((v) => PostVideo.fromJson(Map<String, dynamic>.from(v))).toList();
  }

  Future<List<PostDocument>> getGroupDocuments(String groupId, {int page = 1}) async {
    final response = await _api.getGroupDocuments(groupId: groupId, page: page);
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((d) => PostDocument.fromJson(Map<String, dynamic>.from(d))).toList();
  }

  Future<List<Topic>> getForumTopics(String forumId, {int page = 1}) async {
    final response = await _api.getForumTopics(forumId: forumId, page: page);
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((t) => Topic.fromJson(Map<String, dynamic>.from(t))).toList();
  }

  Future<Topic> getTopic(String topicId) async {
    final response = await _api.getTopic(topicId);
    return Topic.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// Resolves a Feed activity's discussion reference to a real, openable
  /// Topic - a "bbp_topic_create" activity's id IS the topic id directly;
  /// a "bbp_reply_create" activity's id is the reply's own id, whose
  /// `parent` field is the topic id (see GroupsApiService.getReply's doc
  /// comment).
  Future<({Topic topic, String forumId})> resolveDiscussionActivity({
    required String activityType,
    required String discussionId,
  }) async {
    String topicId = discussionId;
    if (activityType == "bbp_reply_create") {
      final replyResponse = await _api.getReply(discussionId);
      final replyData = Map<String, dynamic>.from(replyResponse.data);
      topicId = (replyData['parent'] ?? '').toString();
    }
    final topicResponse = await _api.getTopic(topicId);
    final topicData = Map<String, dynamic>.from(topicResponse.data);
    final topic = Topic.fromJson(topicData);
    final forumId = (topicData['forum_id'] ?? '').toString();
    return (topic: topic, forumId: forumId);
  }

  Future<Topic> createTopic({required String groupId, required String title, required String content}) async {
    final response = await _api.createTopic(groupId: groupId, title: title, content: content);
    return Topic.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<TopicReply>> getTopicReplies(String topicId, {int page = 1}) async {
    final response = await _api.getTopicReplies(topicId: topicId, page: page);
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((r) => TopicReply.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  Future<TopicReply> createReply({required String topicId, required String forumId, required String content}) async {
    final response = await _api.createReply(topicId: topicId, forumId: forumId, content: content);
    return TopicReply.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<GroupAlbum>> getGroupAlbums(String groupId) async {
    final response = await _api.getGroupAlbums(groupId: groupId);
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((a) => GroupAlbum.fromJson(Map<String, dynamic>.from(a))).toList();
  }

  Future<({GroupAlbum album, List<PostPhoto> photos})> getAlbum(String albumId) async {
    final response = await _api.getAlbum(albumId: albumId);
    final data = Map<String, dynamic>.from(response.data);
    final album = GroupAlbum.fromJson(data);
    final mediaList = data['media'] is Map ? (data['media']['medias'] as List? ?? const []) : const [];
    final photos = mediaList.whereType<Map>().map((m) => PostPhoto.fromJson(Map<String, dynamic>.from(m))).toList();
    return (album: album, photos: photos);
  }

  /// Confirmed live 2026-07-22: the create response is wrapped
  /// (`{"created": true, "error": false, "album": {...}}`), not a bare
  /// album object like every other create/update call in this app -
  /// unwrapping `album` was the actual root cause of a real reported bug
  /// (parsing the outer wrapper as the album gave every created album a
  /// blank id, so photos added to it afterward attached to the group's
  /// media pool but never actually linked to the album - present in the
  /// flat Photos tab, missing from the album itself).
  Future<GroupAlbum> createAlbum({required String groupId, required String title}) async {
    final response = await _api.createAlbum(groupId: groupId, title: title);
    final data = Map<String, dynamic>.from(response.data);
    final albumData = data['album'] is Map ? Map<String, dynamic>.from(data['album']) : data;
    return GroupAlbum.fromJson(albumData);
  }

  Future<void> deleteAlbum(String albumId) => _api.deleteAlbum(albumId);

  Future<void> attachMediaToAlbum({required String groupId, required String albumId, required int uploadId}) {
    return _api.attachMediaToAlbum(groupId: groupId, albumId: albumId, uploadId: uploadId);
  }

  Future<void> updateMemberRole({required String groupId, required String userId, required String role}) {
    return _api.updateMemberRole(groupId: groupId, userId: userId, role: role);
  }

  Future<void> removeMemberFromGroup({required String groupId, required String userId}) {
    return _api.removeMemberFromGroup(groupId: groupId, userId: userId);
  }

  Future<void> deleteGroup(String groupId) => _api.deleteGroup(groupId);

  Future<List<GroupSetting>> getGroupSettings({required String groupId, required String nav}) async {
    final response = await _api.getGroupSettings(groupId: groupId, nav: nav);
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((s) => GroupSetting.fromJson(Map<String, dynamic>.from(s))).toList();
  }

  Future<void> updateGroupSettings({
    required String groupId,
    required String nav,
    required Map<String, dynamic> fields,
  }) {
    return _api.updateGroupSettings(groupId: groupId, nav: nav, fields: fields);
  }

  Future<void> uploadGroupAvatar({required String groupId, required File file}) {
    return _api.uploadGroupAvatar(groupId: groupId, file: file);
  }

  Future<void> uploadGroupCover({required String groupId, required File file}) {
    return _api.uploadGroupCover(groupId: groupId, file: file);
  }
}
