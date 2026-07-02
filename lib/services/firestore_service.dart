import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {

Future<UserModel?> getCurrentUser() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return null;

  final doc = await _firestore
      .collection("users")
      .doc(user.uid)
      .get();

  if (!doc.exists) return null;

  return UserModel.fromFirestore(doc.data()!);
}

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> saveUser({
    required String uid,
    required String email,
    required String username,
    required String field,
    required String level,
    required String gender,
    required DateTime birthDate,
    required String bio,
    required String facebook,
    required String linkedin,
  }) async {
    await _firestore
        .collection("users")
        .doc(uid)
        .set({
      "uid": uid,
      "email": email,
      "username": username,
      "field": field,
      "level": level,
      "gender": gender,
      "birthDate": Timestamp.fromDate(birthDate),
      "bio": bio,
      "facebook": facebook,
      "linkedin": linkedin,
      "profileImage": "",
      "coverImage": "",
      "isProfileComplete": true,
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}