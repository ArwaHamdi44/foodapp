import '../services/restaurant_service.dart';
import '../data/models/restaurant.dart';

class RestaurantViewModel {
  final RestaurantService _restaurantService = RestaurantService();

  
  Stream<List<Restaurant>> getRestaurantsStream() {
    return _restaurantService.getRestaurantsStream();
  }

  Future<List<Restaurant>> getRestaurants() async {
    try {
      return await _restaurantService.getRestaurants();
    } catch (e) {
      throw Exception('Failed to fetch restaurants: ${e.toString()}');
    }
  }

  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      return await _restaurantService.getRestaurantById(id);
    } catch (e) {
      throw Exception('Failed to fetch restaurant: ${e.toString()}');
    }
  }

  
  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final restaurants = await _restaurantService.getRestaurants();
      final lowerQuery = query.toLowerCase();
      return restaurants.where((restaurant) {
        return restaurant.name.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search restaurants: ${e.toString()}');
    }
  }
}

