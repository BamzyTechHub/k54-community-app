import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create Post
  Future<void> createPost(Post post) async {
    await _firestore
        .collection("posts")
        .doc(post.id)
        .set(post.toJson());
  }

  /// Get All Posts (Home Feed)
 Stream<List<Post>> getPosts() {
    return _firestore
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Post.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get Posts By User
  Stream<List<Post>> getUserPosts(String userId) {
    return _firestore
        .collection("posts")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Post.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Delete Post
  Future<void> deletePost(String postId) async {
    await _firestore
        .collection("posts")
        .doc(postId)
        .delete();
  }
}