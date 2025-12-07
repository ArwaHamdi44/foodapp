import '../data/models/food.dart';
import '../services/food_service.dart';

class FoodViewModel {
  final FoodService _foodService = FoodService();

  // Get foods by restaurant ID
  Future<List<Food>> getFoodsByRestaurant(String restaurantId) async {
    try {
      return await _foodService.getFoodsByRestaurant(restaurantId);
    } catch (e) {
      throw Exception('Failed to fetch foods: ${e.toString()}');
    }
  }

  // Get all foods
  Future<List<Food>> getAllFoods() async {
    try {
      return await _foodService.getAllFoods();
    } catch (e) {
      throw Exception('Failed to fetch all foods: ${e.toString()}');
    }
  }

  // Get popular foods sorted by rating
  Future<List<Food>> getPopularFoods({int limit = 3}) async {
    try {
      return await _foodService.getPopularFoods(limit: limit);
    } catch (e) {
      throw Exception('Failed to fetch popular foods: ${e.toString()}');
    }
  }

  // Get a single food by ID
  Future<Food?> getFoodById(String foodId) async {
    try {
      return await _foodService.getFoodById(foodId);
    } catch (e) {
      throw Exception('Failed to fetch food: ${e.toString()}');
    }
  }

  // Get add-ons for a specific food item
  Future<List<String>> getAddOnsForFood(String foodId) async {
    try {
      final food = await _foodService.getFoodById(foodId);
      if (food != null && food.addOns != null) {
        return food.addOns!;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch add-ons: ${e.toString()}');
    }
  }

  // Add a new food
  Future<String> addFood(Food food) async {
    try {
      return await _foodService.addFood(food);
    } catch (e) {
      throw Exception('Failed to add food: ${e.toString()}');
    }
  }

  // Update a food
  Future<void> updateFood(String foodId, Food food) async {
    try {
      await _foodService.updateFood(foodId, food);
    } catch (e) {
      throw Exception('Failed to update food: ${e.toString()}');
    }
  }

  // Delete a food
  Future<void> deleteFood(String foodId) async {
    try {
      await _foodService.deleteFood(foodId);
    } catch (e) {
      throw Exception('Failed to delete food: ${e.toString()}');
    }
  }

  Future<List<Food>> searchFoods(String restaurantId, String query) async {
    try {
      final foods = await _foodService.getFoodsByRestaurant(restaurantId);
      final lowerQuery = query.toLowerCase();
      return foods.where((food) {
        return food.name.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search foods: ${e.toString()}');
    }
  }
}