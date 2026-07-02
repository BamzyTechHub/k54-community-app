import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;

  final String field;
  final String level;
  final String gender;

  final DateTime birthDate;

  final String bio;

  final String facebook;

  final String linkedin;

  final String profileImage;

  final String coverImage;

  final bool isProfileComplete;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.field,
    required this.level,
    required this.gender,
    required this.birthDate,
    required this.bio,
    required this.facebook,
    required this.linkedin,
    required this.profileImage,
    required this.coverImage,
    required this.isProfileComplete,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data["uid"] ?? "",
      email: data["email"] ?? "",
      username: data["username"] ?? "",
      field: data["field"] ?? "",
      level: data["level"] ?? "",
      gender: data["gender"] ?? "",
      birthDate: data["birthDate"] != null
    ? (data["birthDate"] as Timestamp).toDate()
    : DateTime.now(),
      bio: data["bio"] ?? "",
      facebook: data["facebook"] ?? "",
      linkedin: data["linkedin"] ?? "",
      profileImage: data["profileImage"] ?? "",
      coverImage: data["coverImage"] ?? "",
      isProfileComplete: data["isProfileComplete"] ?? false,
    );
  }
}