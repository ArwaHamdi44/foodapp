import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get user profile
  Future<User?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc);
  }

  // Get user profile stream
  Stream<User?> getUserProfileStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return User.fromFirestore(snapshot);
    });
  }

  // Create user profile
  Future<void> createUserProfile(User user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  // Update user profile
  Future<void> updateUserProfile(User user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  // Update user saved addresses
  Future<void> updateUserAddresses(String userId, List<String> addresses) async {
    await _db.collection('users').doc(userId).update({
      'savedAddresses': addresses,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

