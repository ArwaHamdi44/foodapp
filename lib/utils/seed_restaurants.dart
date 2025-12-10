import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../services/restaurant_seed_service.dart';

/// Script to seed restaurant locations in the database
/// 
/// Usage:
/// 1. Update the locationData map below with your restaurant IDs and coordinates
/// 2. Or use seedAllRestaurantsFromAddresses() to auto-geocode from addresses
/// 3. Run: dart lib/utils/seed_restaurants.dart
/// 
/// Note: Make sure Firebase is initialized before running this script

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final seedService = RestaurantSeedService();

  // Option 1: Manually provide coordinates for each restaurant
  // Replace with your actual restaurant IDs and coordinates
  final locationData = {
    // Example format:
    // 'restaurant1': {'latitude': 37.7749, 'longitude': -122.4194},
    // 'restaurant2': {'latitude': 37.7849, 'longitude': -122.4094},
    // Add more restaurants here...
  };

  if (locationData.isNotEmpty) {
    print('Using manual location data...\n');
    await seedService.bulkUpdateRestaurantLocations(locationData);
  } else {
    // Option 2: Auto-geocode from addresses
    print('Auto-geocoding restaurants from addresses...\n');
    await seedService.seedAllRestaurantsFromAddresses();
  }

  print('\n✓ Seeding completed!');
}












