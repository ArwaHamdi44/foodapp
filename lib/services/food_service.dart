import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/food.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'foods';

  // Get all foods for a specific restaurant
  Future<List<Food>> getFoodsByRestaurant(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      
      return snapshot.docs
          .map((doc) => Food.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch foods: ${e.toString()}');
    }
  }

  // Get all foods
  Future<List<Food>> getAllFoods() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .get();
      
      return snapshot.docs
          .map((doc) => Food.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all foods: ${e.toString()}');
    }
  }

  // Get popular foods sorted by rating
  Future<List<Food>> getPopularFoods({int limit = 3}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => Food.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch popular foods: ${e.toString()}');
    }
  }

  // Get a single food by ID
  Future<Food?> getFoodById(String foodId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(foodId)
          .get();
      
      if (doc.exists) {
        return Food.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch food: ${e.toString()}');
    }
  }

  // Add a new food
  Future<String> addFood(Food food) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(food.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add food: ${e.toString()}');
    }
  }

  // Update a food
  Future<void> updateFood(String foodId, Food food) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(foodId)
          .update(food.toMap());
    } catch (e) {
      throw Exception('Failed to update food: ${e.toString()}');
    }
  }

  // Delete a food
  Future<void> deleteFood(String foodId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(foodId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete food: ${e.toString()}');
    }
  }
}
