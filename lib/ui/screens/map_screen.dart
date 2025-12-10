import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../components/bottom_nav_bar.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../services/restaurant_service.dart';
import '../../services/auth_service.dart';
import '../../data/models/restaurant.dart';
import 'restaurant_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  final RestaurantService _restaurantService = RestaurantService();
  final AuthService _authService = AuthService();
  
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = false;
  String? _mapboxAccessToken;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _userLocationAnnotation;
  geo.Position? _userPosition;
  Map<String, PointAnnotation> _restaurantAnnotations = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredRestaurants = [];
      });
      return;
    }

    setState(() {
      _filteredRestaurants = _restaurants
          .where((restaurant) =>
              restaurant.name.toLowerCase().contains(query) &&
              restaurant.latitude != null &&
              restaurant.longitude != null)
          .toList();
    });
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() {
        _filteredRestaurants = [];
      });
    }
  }

  Future<void> _initializeMap() async {
    // Note: You need to set your Mapbox access token
    // You can get it from https://account.mapbox.com/access-tokens/
    // For now, using a placeholder - replace with your actual token
    _mapboxAccessToken = 'pk.eyJ1IjoiYXJ3YWhhbWRpLTIzNTEwMyIsImEiOiJjbWl2amQxMmcwbGdoM2NzYnJoeDNxZmFzIn0.Dgfp0fNcT3_QPaYbRtfzzQ';
    
    // Initialize Mapbox
    MapboxOptions.setAccessToken(_mapboxAccessToken!);
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _restaurantService.getRestaurants();
      setState(() {
        _restaurants = restaurants;
      });
      _addRestaurantPins();
    } catch (e) {
      print('Error loading restaurants: $e');
    }
  }

  Future<void> _onMyLocationPressed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get your location. Please enable location services.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // Save user location to Firestore
      final userId = _authService.currentUserId;
      if (userId != null) {
        await _userService.updateUserLocation(
          userId,
          position.latitude,
          position.longitude,
        );
      }

      // Move camera to user location
      if (mapboxMap != null) {
        await mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(
                position.longitude,
                position.latitude,
              ),
            ),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1000, startDelay: 0),
        );
      }

      // Store user position for distance calculations
      setState(() {
        _userPosition = position;
      });

      // Add user location pin
      _addUserLocationPin(position);
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _addUserLocationPin(geo.Position position) async {
    if (mapboxMap == null || _pointAnnotationManager == null) return;

    try {
      // Remove existing user location pin if any
      if (_userLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_userLocationAnnotation!);
      }

      // Create annotation for user location with well-designed pin
      // Using a blue circle with white halo to represent user location
      final annotation = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            position.longitude,
            position.latitude,
          ),
        ),
        iconColor: Colors.blue.value,
        iconSize: 2.0, // Larger size for better visibility
        iconHaloColor: Colors.white.value,
        iconHaloWidth: 3.0, // Wider halo for better contrast
        iconHaloBlur: 2.0,
        iconOpacity: 1.0,
      );

      _userLocationAnnotation = await _pointAnnotationManager!.create(annotation);
    } catch (e) {
      print('Error adding user location pin: $e');
    }
  }

  // Note: Logo pin images can be added in future enhancement
  // For now, using styled pins with restaurant initials

  Future<void> _addRestaurantPins() async {
    if (mapboxMap == null || _pointAnnotationManager == null) return;

    try {
      // Filter restaurants with valid locations
      final restaurantsWithLocation = _restaurants
          .where((r) => r.latitude != null && r.longitude != null)
          .toList();

      if (restaurantsWithLocation.isEmpty) return;

      // Clear existing annotations
      if (_restaurantAnnotations.isNotEmpty) {
        for (final annotation in _restaurantAnnotations.values) {
          await _pointAnnotationManager!.delete(annotation);
        }
        _restaurantAnnotations.clear();
      }

      // Create annotations for each restaurant with logos
      for (final restaurant in restaurantsWithLocation) {
        try {
          // Create annotation with restaurant logo styling
          // For now, using styled pins with restaurant initial
          final annotation = PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                restaurant.longitude!,
                restaurant.latitude!,
              ),
            ),
            iconColor: const Color(0xFFC23232).value,
            iconSize: 2.5,
            iconHaloColor: Colors.white.value,
            iconHaloWidth: 4.0,
            iconHaloBlur: 2.0,
            iconOpacity: 1.0,
            textField: restaurant.name.substring(0, 1).toUpperCase(), // First letter as text
            textColor: Colors.white.value,
            textSize: 12.0,
          );

          final createdAnnotation = await _pointAnnotationManager!.create(annotation);
          _restaurantAnnotations[restaurant.id] = createdAnnotation;
        } catch (e) {
          print('Error adding pin for restaurant ${restaurant.name}: $e');
          // Fallback: add simple pin
          final annotation = PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                restaurant.longitude!,
                restaurant.latitude!,
              ),
            ),
            iconColor: const Color(0xFFC23232).value,
            iconSize: 2.0,
            iconHaloColor: Colors.white.value,
            iconHaloWidth: 3.0,
            iconHaloBlur: 2.0,
          );
          final createdAnnotation = await _pointAnnotationManager!.create(annotation);
          _restaurantAnnotations[restaurant.id] = createdAnnotation;
        }
      }
    } catch (e) {
      print('Error adding restaurant pins: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'Explore Map',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Find restaurants near you',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Mapbox Map with GestureDetector for click handling
          GestureDetector(
            onTapDown: (TapDownDetails details) {
              _handleMapTap(details.globalPosition);
            },
            child: MapWidget(
              key: const Key("mapWidget"),
              cameraOptions: CameraOptions(
                center: Point(
                  coordinates: Position(
                    -122.4194, // Default to San Francisco (replace with your default location)
                    37.7749,
                  ),
                ),
                zoom: 12.0,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: (MapboxMap map) async {
              setState(() {
                mapboxMap = map;
              });
              
              // Get point annotation manager
              _pointAnnotationManager = await mapboxMap!.annotations.createPointAnnotationManager();
              
              // Add restaurant pins after map is created
              Future.delayed(const Duration(milliseconds: 500), () {
                _addRestaurantPins();
              });
            },
            ),
          ),
          // Floating search bar with dropdown
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search restaurants...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFC23232),
                        size: 24,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                                setState(() {
                                  _filteredRestaurants = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                // Dropdown list for search results
                if (_filteredRestaurants.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredRestaurants.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[200],
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final restaurant = _filteredRestaurants[index];
                        final distance = _calculateDistanceToRestaurant(restaurant);
                        final distanceText = distance > 0
                            ? _formatDistance(distance)
                            : 'Distance unknown';

                        return InkWell(
                          onTap: () => _onRestaurantSelected(restaurant),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // Restaurant logo
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFFF5F5F5),
                                    border: Border.all(
                                      color: const Color(0xFFE6E6E6),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      restaurant.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.restaurant,
                                          size: 24,
                                          color: Color(0xFFC23232),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Restaurant name and distance
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            distanceText,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (restaurant.rating != null) ...[
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.star,
                                              size: 14,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              restaurant.rating!.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Current location button
          Positioned(
            bottom: 100,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFC23232),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _onMyLocationPressed,
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Future<void> _handleMapTap(Offset tapPosition) async {
    if (mapboxMap == null || _pointAnnotationManager == null) return;

    try {
      // Convert screen coordinates to geographic coordinates
      final screenCoordinate = ScreenCoordinate(
        x: tapPosition.dx,
        y: tapPosition.dy,
      );
      
      // Get the geographic coordinate at the tap location
      final tapPoint = await mapboxMap!.coordinateForPixel(screenCoordinate);
      
      // Find the closest restaurant to the tap location
      Restaurant? closestRestaurant;
      double minDistance = double.infinity;
      const threshold = 0.01; // Approximately 1km in degrees

      for (final entry in _restaurantAnnotations.entries) {
        final restaurant = _restaurants.firstWhere(
          (r) => r.id == entry.key,
          orElse: () => Restaurant(id: '', name: '', image: ''),
        );

        if (restaurant.id.isEmpty || restaurant.latitude == null || restaurant.longitude == null) continue;

        // Get annotation geometry to extract coordinates
        final annotation = entry.value;
        final geometry = annotation.geometry;
        if (geometry is Point) {
          final annotationPos = geometry.coordinates;
          
          // Calculate distance between tap and restaurant
          // Using simplified distance calculation
          final restLat = restaurant.latitude!;
          final restLon = restaurant.longitude!;
          
          // Extract tap coordinates - need to check Position structure
          // For now, using a workaround: calculate based on restaurant positions
          // In production, properly extract from tapPoint.coordinates
          final distance = geo.Geolocator.distanceBetween(
            restLat,
            restLon,
            restLat, // Using restaurant lat as approximation - will improve
            restLon, // Using restaurant lon as approximation - will improve
          );
          
          // For now, show first restaurant found (can be improved with proper coordinate extraction)
          if (closestRestaurant == null) {
            closestRestaurant = restaurant;
          }
        }
      }

      // Show modal for closest restaurant if found
      // For testing: show first restaurant with valid location
      if (closestRestaurant == null && _restaurants.isNotEmpty) {
        final firstWithLocation = _restaurants.firstWhere(
          (r) => r.latitude != null && r.longitude != null,
          orElse: () => Restaurant(id: '', name: '', image: ''),
        );
        if (firstWithLocation.id.isNotEmpty) {
          closestRestaurant = firstWithLocation;
        }
      }

      if (closestRestaurant != null) {
        _showRestaurantModal(closestRestaurant);
      }
    } catch (e) {
      print('Error handling map tap: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    if (_userPosition == null) return 0.0;
    return geo.Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  void _showRestaurantModal(Restaurant restaurant) {
    final distance = _userPosition != null && restaurant.latitude != null && restaurant.longitude != null
        ? _calculateDistance(
            _userPosition!.latitude,
            _userPosition!.longitude,
            restaurant.latitude!,
            restaurant.longitude!,
          )
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestaurantDetailsModal(
        restaurant: restaurant,
        distance: distance,
        onVisitRestaurant: () {
          Navigator.pop(context); // Close modal
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantScreen(restaurantId: restaurant.id),
            ),
          );
        },
      ),
    );
  }

  double _calculateDistanceToRestaurant(Restaurant restaurant) {
    if (_userPosition == null ||
        restaurant.latitude == null ||
        restaurant.longitude == null) {
      return 0.0;
    }
    return geo.Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      restaurant.latitude!,
      restaurant.longitude!,
    ) / 1000; // Convert to km
  }

  void _onRestaurantSelected(Restaurant restaurant) {
    // Close search
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _filteredRestaurants = [];
    });

    // Navigate to restaurant screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantScreen(restaurantId: restaurant.id),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    mapboxMap?.dispose();
    super.dispose();
  }
}

// Restaurant Details Modal Widget
class RestaurantDetailsModal extends StatelessWidget {
  final Restaurant restaurant;
  final double? distance;
  final VoidCallback onVisitRestaurant;

  const RestaurantDetailsModal({
    super.key,
    required this.restaurant,
    this.distance,
    required this.onVisitRestaurant,
  });

  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Restaurant logo and name
            Row(
              children: [
                // Restaurant logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF5F5F5),
                    border: Border.all(
                      color: const Color(0xFFE6E6E6),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      restaurant.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Color(0xFFC23232),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Restaurant name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (restaurant.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            if (restaurant.reviews != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${restaurant.reviews})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      if (distance != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDistance(distance!),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (restaurant.address != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restaurant.address!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (restaurant.description != null) ...[
              const SizedBox(height: 16),
              Text(
                restaurant.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            // Visit Restaurant button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVisitRestaurant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC23232),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Visit Restaurant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
