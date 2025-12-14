import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc);
  }

  Stream<User?> getUserProfileStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return User.fromFirestore(snapshot);
    });
  }

  Future<void> createUserProfile(User user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> updateUserProfile(User user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserAddresses(String userId, List<String> addresses) async {
    await _db.collection('users').doc(userId).update({
      'savedAddresses': addresses,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserLocation(String userId, double latitude, double longitude) async {
    await _db.collection('users').doc(userId).update({
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

