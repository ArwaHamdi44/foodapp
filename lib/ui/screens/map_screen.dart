import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../components/bottom_nav_bar.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../services/restaurant_service.dart';
import '../../services/auth_service.dart';
import '../../data/models/restaurant.dart';
import '../../utils/map_pin_helper.dart';
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
    _getUserLocationAndCenter(); // Get user location on init
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

  /// Get user location and center map on it initially
  Future<void> _getUserLocationAndCenter() async {
    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      if (position == null) {
        print('Unable to get user location on init');
        return;
      }

      // Store user position for distance calculations
      setState(() {
        _userPosition = position;
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

      // Wait for map to be ready, then center and add user pin
      Future.delayed(const Duration(milliseconds: 800), () async {
        if (mapboxMap != null) {
          await mapboxMap!.flyTo(
            CameraOptions(
              center: Point(
                coordinates: Position(
                  position.longitude,
                  position.latitude,
                ),
              ),
              zoom: 14.0,
            ),
            MapAnimationOptions(duration: 1000, startDelay: 0),
          );
        }
        
        // Add user location pin with custom design
        _addUserLocationPin(position);
      });
    } catch (e) {
      print('Error getting initial location: $e');
    }
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
    if (mapboxMap == null || _pointAnnotationManager == null) {
      print('Cannot add user pin: map or annotation manager is null');
      return;
    }

    try {
      // Remove existing user location pin if any
      if (_userLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_userLocationAnnotation!);
      }

      print('Adding user location pin at: ${position.latitude}, ${position.longitude}');

      // Generate custom user location pin image
      final userPinImage = await MapPinHelper.generateUserLocationPin();
      final userPinBytes = await MapPinHelper.imageToBytes(userPinImage);

      // Try to add image to map style with error handling
      try {
        final mbxImage = MbxImage(
          width: 48,
          height: 48,
          data: userPinBytes,
        );
        await mapboxMap!.style.addStyleImage('user-location-pin', 1.0, mbxImage, false, [], [], null);
        print('Custom user location image added successfully');
      } catch (e) {
        print('Note: Could not add custom image, using default pin: $e');
      }

      // Create annotation for user location with custom modern design
      final annotation = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            position.longitude,
            position.latitude,
          ),
        ),
        iconImage: 'user-location-pin',
        iconSize: 1.2,
        iconAnchor: IconAnchor.CENTER,
      );

      _userLocationAnnotation = await _pointAnnotationManager!.create(annotation);
      print('User location annotation created with id: ${_userLocationAnnotation!.id}');
    } catch (e) {
      print('Error adding user location pin: $e');
      // Fallback to simple pin
      try {
        final annotation = PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              position.longitude,
              position.latitude,
            ),
          ),
          iconColor: Colors.blue.value,
          iconSize: 2.5,
          iconHaloColor: Colors.white.value,
          iconHaloWidth: 4.0,
        );
        _userLocationAnnotation = await _pointAnnotationManager!.create(annotation);
        print('Fallback user location pin created with id: ${_userLocationAnnotation!.id}');
      } catch (fallbackError) {
        print('Fallback pin also failed: $fallbackError');
      }
    }
  }

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

      // Create annotations for each restaurant with their logos
      for (final restaurant in restaurantsWithLocation) {
        try {
          // Generate a custom marker with the restaurant logo
          final markerImage = await _generateRestaurantMarker(restaurant);
          if (markerImage != null) {
            final markerBytes = await MapPinHelper.imageToBytes(markerImage);
            final imageId = 'restaurant-marker-${restaurant.id}';
            
            // Try to add image to map style
            try {
              final mbxImage = MbxImage(
                width: 60,
                height: 60,
                data: markerBytes,
              );
              await mapboxMap!.style.addStyleImage(imageId, 1.0, mbxImage, false, [], [], null);
            } catch (e) {
              print('Could not add custom image for ${restaurant.name}: $e');
            }

            // Create annotation with restaurant logo
            final annotation = PointAnnotationOptions(
              geometry: Point(
                coordinates: Position(
                  restaurant.longitude!,
                  restaurant.latitude!,
                ),
              ),
              iconImage: imageId,
              iconSize: 1.0,
              iconAnchor: IconAnchor.BOTTOM,
            );

            final createdAnnotation = await _pointAnnotationManager!.create(annotation);
            _restaurantAnnotations[restaurant.id] = createdAnnotation;
          }
        } catch (e) {
          print('Error adding pin for restaurant ${restaurant.name}: $e');
          // Fallback: use default restaurant pin
          await _addDefaultRestaurantPin(restaurant);
        }
      }
    } catch (e) {
      print('Error adding restaurant pins: $e');
    }
  }

  /// Generate a custom marker with restaurant logo
  Future<ui.Image?> _generateRestaurantMarker(Restaurant restaurant) async {
    try {
      const size = 60.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw teardrop pin shape
      final paint = Paint()..color = const Color(0xFFC23232);
      
      // Pin body path
      final path = Path();
      const pinWidth = size * 0.8;
      const pinHeight = size;
      const pinRadius = pinWidth / 2;
      
      // Create teardrop shape
      path.moveTo(pinWidth / 2, 0);
      path.arcToPoint(
        Offset(pinWidth, pinRadius),
        radius: Radius.circular(pinRadius),
        clockwise: false,
      );
      path.arcToPoint(
        Offset(pinWidth / 2, pinHeight),
        radius: Radius.circular(pinRadius),
        clockwise: false,
      );
      path.lineTo(pinWidth / 2, pinHeight * 0.8);
      path.close();
      
      // Draw shadow
      paint.color = Colors.black.withOpacity(0.2);
      canvas.drawPath(path, paint);
      
      // Draw pin body
      paint.color = const Color(0xFFC23232);
      canvas.drawPath(path, paint);
      
      // Draw white circle for logo
      paint.color = Colors.white;
      canvas.drawCircle(
        Offset(pinWidth / 2, pinRadius),
        pinRadius * 0.7,
        paint,
      );
      
      // Try to load and draw restaurant logo
      try {
        final image = await _loadNetworkImage(restaurant.image);
        if (image != null) {
          final logoSize = pinRadius * 1.3;
          final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
          final dstRect = Rect.fromLTWH(
            (pinWidth / 2) - (logoSize / 2),
            pinRadius - (logoSize / 2),
            logoSize,
            logoSize,
          );
          
          // Clip to circle
          canvas.save();
          canvas.clipPath(
            Path()..addOval(Rect.fromCircle(
              center: Offset(pinWidth / 2, pinRadius),
              radius: pinRadius * 0.65,
            )),
          );
          canvas.drawImageRect(image, srcRect, dstRect, Paint());
          canvas.restore();
        } else {
          // Draw restaurant icon as fallback
          _drawRestaurantIcon(canvas, pinWidth / 2, pinRadius, pinRadius * 0.5);
        }
      } catch (e) {
        // Draw restaurant icon as fallback
        _drawRestaurantIcon(canvas, pinWidth / 2, pinRadius, pinRadius * 0.5);
      }
      
      final picture = recorder.endRecording();
      return await picture.toImage(size.toInt(), size.toInt());
    } catch (e) {
      print('Error generating restaurant marker: $e');
      return null;
    }
  }

  /// Draw a restaurant fork and knife icon
  void _drawRestaurantIcon(Canvas canvas, double x, double y, double size) {
    final paint = Paint()
      ..color = const Color(0xFFC23232)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Fork (left side)
    canvas.drawLine(
      Offset(x - size * 0.3, y - size * 0.4),
      Offset(x - size * 0.3, y + size * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(x - size * 0.45, y - size * 0.2),
      Offset(x - size * 0.15, y - size * 0.2),
      paint,
    );

    // Knife (right side)
    canvas.drawLine(
      Offset(x + size * 0.3, y - size * 0.4),
      Offset(x + size * 0.3, y + size * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(x + size * 0.15, y - size * 0.2),
      Offset(x + size * 0.45, y - size * 0.2),
      paint,
    );
  }

  /// Load network image for restaurant logo
  Future<ui.Image?> _loadNetworkImage(String url) async {
    try {
      final completer = Completer<ui.Image?>();
      final image = NetworkImage(url);
      final stream = image.resolve(const ImageConfiguration());
      
      stream.addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info.image);
        }, onError: (dynamic exception, StackTrace? stackTrace) {
          completer.complete(null);
        }),
      );
      
      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Add a default restaurant pin (fallback)
  Future<void> _addDefaultRestaurantPin(Restaurant restaurant) async {
    try {
      final restaurantPinImage = await MapPinHelper.generateRestaurantPin();
      final restaurantPinBytes = await MapPinHelper.imageToBytes(restaurantPinImage);
      final imageId = 'default-restaurant-pin-${restaurant.id}';
      
      try {
        final mbxImage = MbxImage(
          width: 48,
          height: 48,
          data: restaurantPinBytes,
        );
        await mapboxMap!.style.addStyleImage(imageId, 1.0, mbxImage, false, [], [], null);
      } catch (e) {
        print('Could not add default image: $e');
      }

      final annotation = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            restaurant.longitude!,
            restaurant.latitude!,
          ),
        ),
        iconImage: imageId,
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      );

      final createdAnnotation = await _pointAnnotationManager!.create(annotation);
      _restaurantAnnotations[restaurant.id] = createdAnnotation;
    } catch (e) {
      print('Error adding default pin: $e');
      // Final fallback: simple colored pin
      try {
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
        );
        final createdAnnotation = await _pointAnnotationManager!.create(annotation);
        _restaurantAnnotations[restaurant.id] = createdAnnotation;
      } catch (finalError) {
        print('All fallbacks failed: $finalError');
      }
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
              
              // Set up annotation click listener
              _pointAnnotationManager!.addOnPointAnnotationClickListener(_AnnotationClickListener(
                onAnnotationClick: _handleAnnotationClick,
              ));
              
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

                        return Padding(
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
                              // Action buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // View on Map button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.map_outlined,
                                        size: 20,
                                        color: Color(0xFFC23232),
                                      ),
                                      tooltip: 'View on map',
                                      onPressed: () => _centerMapOnRestaurant(restaurant),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Visit Restaurant button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC23232),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Visit restaurant',
                                      onPressed: () => _onRestaurantSelected(restaurant),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  /// Handle direct annotation clicks (more reliable than gesture detector)
  void _handleAnnotationClick(PointAnnotation annotation) {
    print('Annotation clicked: ${annotation.id}');
    
    // Check if it's the user location annotation
    if (_userLocationAnnotation != null && annotation.id == _userLocationAnnotation!.id) {
      print('User location annotation clicked!');
      _showUserLocationModal();
      return;
    }
    
    // Check if it's a restaurant annotation
    for (final entry in _restaurantAnnotations.entries) {
      if (entry.value.id == annotation.id) {
        final restaurant = _restaurants.firstWhere(
          (r) => r.id == entry.key,
          orElse: () => Restaurant(id: '', name: '', image: ''),
        );
        
        if (restaurant.id.isNotEmpty) {
          print('Restaurant annotation clicked: ${restaurant.name}');
          _showRestaurantModal(restaurant);
          return;
        }
      }
    }
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
      final tapLat = tapPoint.coordinates.lat.toDouble();
      final tapLng = tapPoint.coordinates.lng.toDouble();
      
      print('Tap detected at: $tapLat, $tapLng');
      
      // Check if user location marker was tapped (increased threshold for easier tapping)
      if (_userPosition != null && _userLocationAnnotation != null) {
        final distanceToUser = geo.Geolocator.distanceBetween(
          tapLat,
          tapLng,
          _userPosition!.latitude,
          _userPosition!.longitude,
        );
        
        print('Distance to user location: ${distanceToUser}m');
        
        // If tap is within 200 meters of user location, show user location modal (increased from 50m)
        if (distanceToUser < 200) {
          print('Showing user location modal');
          _showUserLocationModal();
          return;
        }
      }
      
      // Find the closest restaurant to the tap location
      Restaurant? closestRestaurant;
      double minDistance = double.infinity;
      const threshold = 200.0; // 200 meters threshold for tap detection (increased from 100m)

      for (final entry in _restaurantAnnotations.entries) {
        final restaurant = _restaurants.firstWhere(
          (r) => r.id == entry.key,
          orElse: () => Restaurant(id: '', name: '', image: ''),
        );

        if (restaurant.id.isEmpty || restaurant.latitude == null || restaurant.longitude == null) continue;

        // Calculate distance between tap and restaurant
        final distance = geo.Geolocator.distanceBetween(
          tapLat,
          tapLng,
          restaurant.latitude!,
          restaurant.longitude!,
        );
        
        // Find closest restaurant within threshold
        if (distance < threshold && distance < minDistance) {
          minDistance = distance;
          closestRestaurant = restaurant;
        }
      }

      // Show modal for closest restaurant if found
      if (closestRestaurant != null) {
        print('Showing restaurant modal for: ${closestRestaurant.name}');
        _showRestaurantModal(closestRestaurant);
      } else {
        print('No marker found within threshold');
      }
    } catch (e) {
      print('Error handling map tap: $e');
    }
  }

  /// Show modal for user's current location
  void _showUserLocationModal() {
    print('_showUserLocationModal called');
    
    if (_userPosition == null) {
      print('Cannot show user location modal: _userPosition is null');
      return;
    }

    print('Showing user location modal at: ${_userPosition!.latitude}, ${_userPosition!.longitude}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserLocationModal(
        position: _userPosition!,
        nearbyRestaurantsCount: _restaurants
            .where((r) => 
              r.latitude != null && 
              r.longitude != null &&
              geo.Geolocator.distanceBetween(
                _userPosition!.latitude,
                _userPosition!.longitude,
                r.latitude!,
                r.longitude!,
              ) < 5000 // Within 5km
            )
            .length,
      ),
    );
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

  /// Center map on selected restaurant from search
  Future<void> _centerMapOnRestaurant(Restaurant restaurant) async {
    if (mapboxMap == null || restaurant.latitude == null || restaurant.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant location not available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Close search dropdown
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _filteredRestaurants = [];
    });

    // Animate camera to restaurant location
    await mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            restaurant.longitude!,
            restaurant.latitude!,
          ),
        ),
        zoom: 16.0, // Zoom in closer to see the restaurant
      ),
      MapAnimationOptions(duration: 1500, startDelay: 0),
    );

    // Wait for animation to complete, then show restaurant details modal
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        _showRestaurantModal(restaurant);
      }
    });
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
                  'View Menu & Order',
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

// Annotation Click Listener
class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final Function(PointAnnotation) onAnnotationClick;

  _AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}

// User Location Modal Widget
class UserLocationModal extends StatelessWidget {
  final geo.Position position;
  final int nearbyRestaurantsCount;

  const UserLocationModal({
    super.key,
    required this.position,
    required this.nearbyRestaurantsCount,
  });

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
            // Icon and title
            Row(
              children: [
                // User location icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and details
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Current position on map',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Location coordinates card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Coordinates',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${position.latitude.toStringAsFixed(6)}\nLng: ${position.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Nearby restaurants info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC23232).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC23232).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 24,
                      color: Color(0xFFC23232),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nearbyRestaurantsCount Restaurants Nearby',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Within 5 km radius',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Info text
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap on restaurant markers to view their details and menu',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
