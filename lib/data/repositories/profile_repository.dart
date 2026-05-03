import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Repository profil user, disimpan di Firestore di
/// `users/{uid}/profile/data`.
class ProfileRepository {
  ProfileRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('users').doc(uid).collection('profile').doc('data');

  Future<UserProfile?> fetch() async {
    final snap = await _doc.get();
    final data = snap.data();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  /// Stream profile reactive — emit `null` saat dokumen belum ada.
  Stream<UserProfile?> watch() {
    return _doc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return UserProfile.fromMap(data);
    });
  }

  Future<void> save(UserProfile profile) async {
    await _doc.set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> clear() async {
    await _doc.delete();
  }
}
