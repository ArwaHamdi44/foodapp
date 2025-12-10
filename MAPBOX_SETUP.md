# Mapbox Integration Setup Guide

This guide will help you set up Mapbox API integration for your food app.

## Prerequisites

1. A Mapbox account (sign up at https://account.mapbox.com/)
2. A Mapbox access token

## Steps to Complete Setup

### 1. Get Your Mapbox Access Token

1. Go to https://account.mapbox.com/access-tokens/
2. Sign in or create a Mapbox account
3. Copy your default public token or create a new one
4. Keep this token secure - you'll need it in the next step

### 2. Configure Mapbox Access Token

Open `lib/ui/screens/map_screen.dart` and replace `YOUR_MAPBOX_ACCESS_TOKEN` on line 41 with your actual Mapbox access token:

```dart
_mapboxAccessToken = 'pk.eyJ1IjoieW91cnVzZXJuYW1lIiwiYSI6ImN...'; // Your actual token
```

### 3. Install Dependencies

Run the following command in your project root:

```bash
flutter pub get
```

### 4. Platform-Specific Setup

#### Android

The location permissions have already been added to `android/app/src/main/AndroidManifest.xml`.

#### iOS

The location permissions have already been added to `ios/Runner/Info.plist`.

### 5. Store Restaurant Locations

When adding restaurants through the admin panel, you can now include latitude and longitude coordinates. The `AdminRestaurantService.addRestaurant()` method accepts optional `latitude` and `longitude` parameters.

Example:
```dart
await adminRestaurantService.addRestaurant(
  id: 'restaurant1',
  name: 'My Restaurant',
  description: 'A great place to eat',
  address: '123 Main St',
  logoUrl: 'https://...',
  backgroundUrl: 'https://...',
  latitude: 37.7749,  // Optional
  longitude: -122.4194, // Optional
);
```

### 6. User Location

When users click the "My Location" button on the map screen:
- The app will request location permissions (if not already granted)
- Get the user's current location
- Save the location to Firestore in the user's document
- Display the user's location on the map with a blue pin

### 7. Restaurant Pins

All restaurants with valid latitude and longitude coordinates will automatically appear on the map with red pins (matching your app's theme color #C23232).

## Features Implemented

✅ User location storage in Firestore
✅ Restaurant location storage in Firestore
✅ Mapbox map integration
✅ User location pin (blue) when clicking "My Location" button
✅ Restaurant pins (red) on the map
✅ Location permissions for Android and iOS
✅ Location service for getting user coordinates

## Testing

1. Run the app on a device or emulator with location services enabled
2. Navigate to the Map screen
3. Click the "My Location" button to see your location on the map
4. Verify that restaurants with location data appear as pins on the map

## Troubleshooting

- **Map not loading**: Check that your Mapbox access token is correctly set
- **Location not working**: Ensure location permissions are granted in device settings
- **Restaurant pins not showing**: Verify that restaurants have latitude and longitude values in Firestore












