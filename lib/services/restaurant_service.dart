import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/restaurant.dart';

class RestaurantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all restaurants stream
  Stream<List<Restaurant>> getRestaurantsStream() {
    return _db.collection('restaurants').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .toList();
    });
  }

  // Get all restaurants (one-time fetch)
  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection('restaurants').get();
    return snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc))
        .toList();
  }

  // Get restaurant by ID
  Future<Restaurant?> getRestaurantById(String id) async {
    final doc = await _db.collection('restaurants').doc(id).get();
    if (!doc.exists) return null;
    return Restaurant.fromFirestore(doc);
  }
  
}

