class Post {
  final String id;
  final String username;
  final String profession;
  final String profileImage;
  final String caption;
  final String postImage;
  final int likes;
  final int comments;
  final int shares;

  Post({
    required this.id,
    required this.username,
    required this.profession,
    required this.profileImage,
    required this.caption,
    required this.postImage,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  // Convert API JSON to Post object
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json["id"].toString(),
      username: json["username"],
      profession: json["profession"],
      profileImage: json["profileImage"],
      caption: json["caption"],
      postImage: json["postImage"],
      likes: json["likes"],
      comments: json["comments"],
      shares: json["shares"],
    );
  }

  // Convert Post object to JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "profession": profession,
      "profileImage": profileImage,
      "caption": caption,
      "postImage": postImage,
      "likes": likes,
      "comments": comments,
      "shares": shares,
    };
  }
}