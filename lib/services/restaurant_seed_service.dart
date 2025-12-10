import 'package:geocoding/geocoding.dart';
import 'restaurant_service.dart';
import 'admin_restaurant_service.dart';

class RestaurantSeedService {
  final RestaurantService _restaurantService = RestaurantService();
  final AdminRestaurantService _adminRestaurantService = AdminRestaurantService();

  /// Update a single restaurant's location by converting address to coordinates
  Future<bool> updateRestaurantLocationFromAddress(String restaurantId) async {
    try {
      final restaurant = await _restaurantService.getRestaurantById(restaurantId);
      if (restaurant == null) {
        print('Restaurant not found: $restaurantId');
        return false;
      }

      if (restaurant.address == null || restaurant.address!.isEmpty) {
        print('Restaurant ${restaurant.name} has no address');
        return false;
      }

      print('Attempting to geocode: ${restaurant.name} - ${restaurant.address}');

      // Geocode the address with better error handling
      List<Location> locations;
      try {
        locations = await locationFromAddress(restaurant.address!);
      } catch (e) {
        print('Geocoding failed for ${restaurant.name}: $e');
        // Try with simplified address (remove Plus Codes and postal codes)
        final simplifiedAddress = _simplifyAddress(restaurant.address!);
        if (simplifiedAddress != restaurant.address && simplifiedAddress.isNotEmpty) {
          print('Trying simplified address: $simplifiedAddress');
          try {
            final retryLocations = await locationFromAddress(simplifiedAddress);
            if (retryLocations.isNotEmpty) {
              final location = retryLocations.first;
              if (!location.latitude.isNaN && !location.longitude.isNaN &&
                  !(location.latitude == 0.0 && location.longitude == 0.0)) {
                await _adminRestaurantService.updateRestaurantLocation(
                  restaurantId,
                  location.latitude,
                  location.longitude,
                );
                print('✓ Updated ${restaurant.name} using simplified address: (${location.latitude}, ${location.longitude})');
                return true;
              }
            }
          } catch (e3) {
            print('Simplified address geocoding also failed: $e3');
          }
        }
        print('⚠ Could not geocode ${restaurant.name}. Address: ${restaurant.address}');
        print('   You may need to manually set coordinates for this restaurant.');
        return false;
      }

      if (locations.isEmpty) {
        print('Could not geocode address for ${restaurant.name}: ${restaurant.address}');
        return false;
      }

      final location = locations.first;
      
      // Validate coordinates
      if (location.latitude.isNaN || location.longitude.isNaN ||
          location.latitude == 0.0 && location.longitude == 0.0) {
        print('Invalid coordinates received for ${restaurant.name}');
        return false;
      }

      await _adminRestaurantService.updateRestaurantLocation(
        restaurantId,
        location.latitude,
        location.longitude,
      );

      print('✓ Updated ${restaurant.name}: (${location.latitude}, ${location.longitude})');
      return true;
    } catch (e, stackTrace) {
      print('Error updating location for restaurant $restaurantId: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Update a restaurant's location with provided coordinates
  Future<bool> updateRestaurantLocationManually(
    String restaurantId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _adminRestaurantService.updateRestaurantLocation(
        restaurantId,
        latitude,
        longitude,
      );
      final restaurant = await _restaurantService.getRestaurantById(restaurantId);
      print('✓ Updated ${restaurant?.name ?? restaurantId}: ($latitude, $longitude)');
      return true;
    } catch (e) {
      print('Error updating location for restaurant $restaurantId: $e');
      return false;
    }
  }

  /// Seed all restaurants with locations from their addresses
  Future<Map<String, bool>> seedAllRestaurantsFromAddresses() async {
    try {
      final restaurants = await _restaurantService.getRestaurants();
      final results = <String, bool>{};

      print('Found ${restaurants.length} restaurants to process...\n');

      for (final restaurant in restaurants) {
        // Skip if already has location
        if (restaurant.latitude != null && restaurant.longitude != null) {
          print('⊘ ${restaurant.name} already has location, skipping');
          results[restaurant.id] = true;
          continue;
        }

        // Skip if no address
        if (restaurant.address == null || restaurant.address!.isEmpty) {
          print('⊘ ${restaurant.name} has no address, skipping');
          results[restaurant.id] = false;
          continue;
        }

        final success = await updateRestaurantLocationFromAddress(restaurant.id);
        results[restaurant.id] = success;

        // Add a small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final successCount = results.values.where((v) => v == true).length;
      print('\n✓ Completed: $successCount/${restaurants.length} restaurants updated');
      return results;
    } catch (e) {
      print('Error seeding restaurants: $e');
      return {};
    }
  }

  /// Bulk update restaurants with provided location data
  /// Format: Map<restaurantId, {latitude: double, longitude: double}>
  Future<void> bulkUpdateRestaurantLocations(
    Map<String, Map<String, double>> locationData,
  ) async {
    print('Updating ${locationData.length} restaurants with provided locations...\n');

    for (final entry in locationData.entries) {
      final restaurantId = entry.key;
      final location = entry.value;
      final latitude = location['latitude']!;
      final longitude = location['longitude']!;

      await updateRestaurantLocationManually(restaurantId, latitude, longitude);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('\n✓ Bulk update completed');
  }

  /// Simplify address by removing Plus Codes and other codes that might confuse geocoders
  String _simplifyAddress(String address) {
    // Remove Plus Codes (format: 4J4G+8F)
    String simplified = address.replaceAll(RegExp(r'\b[A-Z0-9]+\+[A-Z0-9]+\b'), '').trim();
    
    // Remove postal codes at the end if they're standalone numbers
    simplified = simplified.replaceAll(RegExp(r'\b\d{5,}\b$'), '').trim();
    
    // Clean up multiple commas and spaces
    simplified = simplified.replaceAll(RegExp(r',\s*,+'), ',').trim();
    simplified = simplified.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return simplified;
  }
}

