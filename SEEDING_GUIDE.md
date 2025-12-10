# Restaurant Location Seeding Guide

This guide explains how to seed your database with latitude and longitude coordinates for restaurants.

## Methods Available

### Method 1: Using the Admin Panel (Recommended)

1. **Navigate to Admin Panel**
   - Log in as an admin user
   - You'll see the Admin Panel screen

2. **Click "Seed Locations" Button**
   - This opens the Seed Locations screen
   - Shows statistics: restaurants with/without locations
   - Lists all restaurants and their status

3. **Auto-Seed from Addresses**
   - Click the "Seed from Addresses" button
   - The app will automatically geocode restaurant addresses to get coordinates
   - Progress is shown in real-time
   - Restaurants that already have locations are skipped

### Method 2: Manual Seeding via Code

You can manually provide coordinates for specific restaurants:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/restaurant_seed_service.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final seedService = RestaurantSeedService();

  // Update specific restaurant
  await seedService.updateRestaurantLocationManually(
    'restaurant-id-1',
    37.7749,  // latitude
    -122.4194, // longitude
  );
}
```

### Method 3: Bulk Update via Code

For bulk updates with known coordinates:

```dart
final locationData = {
  'restaurant-id-1': {'latitude': 37.7749, 'longitude': -122.4194},
  'restaurant-id-2': {'latitude': 37.7849, 'longitude': -122.4094},
  'restaurant-id-3': {'latitude': 37.7649, 'longitude': -122.4294},
};

await seedService.bulkUpdateRestaurantLocations(locationData);
```

## Services Available

### RestaurantSeedService

- `updateRestaurantLocationFromAddress(String restaurantId)` - Geocode address to get coordinates
- `updateRestaurantLocationManually(String restaurantId, double lat, double lon)` - Set coordinates manually
- `seedAllRestaurantsFromAddresses()` - Process all restaurants automatically
- `bulkUpdateRestaurantLocations(Map<String, Map<String, double>>)` - Bulk update with provided data

### RestaurantLocationService

- `getRestaurantsWithoutLocation()` - Get list of restaurants needing coordinates
- `getRestaurantsWithLocation()` - Get list of restaurants with coordinates
- `updateLocation(String restaurantId, double lat, double lon)` - Update single restaurant
- `batchUpdateLocations(Map<String, Map<String, double>>)` - Batch update multiple restaurants

## Important Notes

1. **Address Format**: For best geocoding results, ensure restaurant addresses are complete and accurate (e.g., "123 Main St, City, State, Country")

2. **Rate Limiting**: The geocoding service may have rate limits. The seeding process includes delays to avoid issues.

3. **Existing Locations**: Restaurants that already have latitude and longitude will be skipped during auto-seeding.

4. **Error Handling**: If an address cannot be geocoded, that restaurant will be skipped and you'll see an error message.

5. **Manual Updates**: You can always manually update restaurant locations through the admin panel or by using the service methods directly.

## Finding Restaurant IDs

To find restaurant IDs in Firestore:
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Open the `restaurants` collection
4. Each document ID is the restaurant ID

## Example: Seeding Specific Restaurants

If you know the coordinates for specific restaurants, you can update them directly:

```dart
final seedService = RestaurantSeedService();

// Update restaurant with ID "restaurant1"
await seedService.updateRestaurantLocationManually(
  'restaurant1',
  40.7128,  // New York City latitude
  -74.0060, // New York City longitude
);
```

## Troubleshooting

- **"Restaurant has no address"**: Make sure the restaurant has an address field in Firestore
- **"Could not geocode address"**: The address might be incomplete or invalid. Try updating it manually
- **Geocoding fails**: Check your internet connection and ensure the geocoding package is properly installed












