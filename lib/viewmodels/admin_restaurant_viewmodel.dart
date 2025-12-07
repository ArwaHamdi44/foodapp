import '../services/admin_restaurant_service.dart';

class AdminRestaurantViewModel {
  final AdminRestaurantService _service = AdminRestaurantService();

  Future<void> addRestaurant({
    required String id,
    required String name,
    required String description,
    required String address,
    required String logoUrl,
    required String backgroundUrl,
  }) async {
    await _service.addRestaurant(
      id: id,
      name: name,
      description: description,
      address: address,
      logoUrl: logoUrl,
      backgroundUrl: backgroundUrl,
    );
  }
}