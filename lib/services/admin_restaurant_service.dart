import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addRestaurant({
    required String id,
    required String name,
    required String description,
    required String address,
    required String logoUrl,
    required String backgroundUrl,
    double? latitude,
    double? longitude,
  }) async {
    // Use set() with the custom ID instead of add()
    await _firestore.collection('restaurants').doc(id).set({
      'name': name,
      'description': description,
      'address': address,
      'image': logoUrl,
      'backgroundImage': backgroundUrl,
      'rating': null,
      'reviews': null,
      'phone': null,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update restaurant location
  Future<void> updateRestaurantLocation(String restaurantId, double latitude, double longitude) async {
    await _firestore.collection('restaurants').doc(restaurantId).update({
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}