import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_service.dart';
import 'admin_restaurant_service.dart';
import '../data/models/restaurant.dart';

class RestaurantLocationService {
  final RestaurantService _restaurantService = RestaurantService();
  final AdminRestaurantService _adminRestaurantService = AdminRestaurantService();

  Future<List<Restaurant>> getRestaurantsWithoutLocation() async {
    final allRestaurants = await _restaurantService.getRestaurants();
    return allRestaurants
        .where((r) => r.latitude == null || r.longitude == null)
        .toList();
  }

  Future<List<Restaurant>> getRestaurantsWithLocation() async {
    final allRestaurants = await _restaurantService.getRestaurants();
    return allRestaurants
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();
  }

  Future<void> updateLocation(
    String restaurantId,
    double latitude,
    double longitude,
  ) async {
    await _adminRestaurantService.updateRestaurantLocation(
      restaurantId,
      latitude,
      longitude,
    );
  }

  Future<void> batchUpdateLocations(
    Map<String, Map<String, double>> locations,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final entry in locations.entries) {
      final restaurantId = entry.key;
      final location = entry.value;
      final ref = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId);

      batch.update(ref, {
        'latitude': location['latitude']!,
        'longitude': location['longitude']!,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}












