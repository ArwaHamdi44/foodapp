import 'package:flutter/material.dart';
import '../../services/restaurant_seed_service.dart';
import '../../services/restaurant_location_service.dart';
import '../../data/models/restaurant.dart';

class SeedLocationsScreen extends StatefulWidget {
  const SeedLocationsScreen({super.key});

  @override
  State<SeedLocationsScreen> createState() => _SeedLocationsScreenState();
}

class _SeedLocationsScreenState extends State<SeedLocationsScreen> {
  final RestaurantSeedService _seedService = RestaurantSeedService();
  final RestaurantLocationService _locationService = RestaurantLocationService();
  
  List<Restaurant> _restaurantsWithoutLocation = [];
  List<Restaurant> _restaurantsWithLocation = [];
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final withoutLocation = await _locationService.getRestaurantsWithoutLocation();
      final withLocation = await _locationService.getRestaurantsWithLocation();
      
      setState(() {
        _restaurantsWithoutLocation = withoutLocation;
        _restaurantsWithLocation = withLocation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading restaurants: $e';
      });
    }
  }

  Future<void> _seedFromAddresses() async {
    setState(() {
      _isSeeding = true;
      _statusMessage = 'Seeding restaurant locations from addresses...';
    });

    try {
      final results = await _seedService.seedAllRestaurantsFromAddresses();
      final successCount = results.values.where((v) => v == true).length;
      
      setState(() {
        _isSeeding = false;
        _statusMessage = 'Seeded $successCount restaurants successfully!';
      });

      // Reload restaurants
      await _loadRestaurants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully seeded $successCount restaurants'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _statusMessage = 'Error seeding: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: const Text(
          'Seed Restaurant Locations',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  if (_statusMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _isSeeding ? Colors.blue[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSeeding ? Colors.blue : Colors.green,
                        ),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isSeeding ? Colors.blue[900] : Colors.green[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'With Location',
                          '${_restaurantsWithLocation.length}',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Without Location',
                          '${_restaurantsWithoutLocation.length}',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Seed Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSeeding || _restaurantsWithoutLocation.isEmpty
                          ? null
                          : _seedFromAddresses,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC23232),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSeeding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Seed from Addresses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Restaurants without location
                  if (_restaurantsWithoutLocation.isNotEmpty) ...[
                    const Text(
                      'Restaurants Without Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._restaurantsWithoutLocation.map((restaurant) => 
                      _buildRestaurantCard(restaurant, hasLocation: false),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Restaurants with location
                  if (_restaurantsWithLocation.isNotEmpty) ...[
                    const Text(
                      'Restaurants With Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._restaurantsWithLocation.map((restaurant) => 
                      _buildRestaurantCard(restaurant, hasLocation: true),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, {required bool hasLocation}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLocation ? Colors.green : Colors.orange,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (restaurant.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    restaurant.address!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (hasLocation && restaurant.latitude != null && restaurant.longitude != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${restaurant.latitude!.toStringAsFixed(6)}, ${restaurant.longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasLocation)
                IconButton(
                  icon: const Icon(Icons.edit_location, size: 20),
                  color: const Color(0xFFC23232),
                  onPressed: () => _showManualLocationDialog(restaurant),
                  tooltip: 'Set location manually',
                ),
              Icon(
                hasLocation ? Icons.check_circle : Icons.location_off,
                color: hasLocation ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showManualLocationDialog(Restaurant restaurant) {
    final latController = TextEditingController();
    final lonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Set Location: ${restaurant.name}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.address != null) ...[
              Text(
                'Address: ${restaurant.address}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 30.0444',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFC23232),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., 31.2357',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFC23232),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: You can find coordinates using Google Maps',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final latText = latController.text.trim();
              final lonText = lonController.text.trim();

              if (latText.isEmpty || lonText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter both latitude and longitude'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final lat = double.tryParse(latText);
              final lon = double.tryParse(lonText);

              if (lat == null || lon == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid coordinates. Please enter valid numbers'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid coordinate range. Lat: -90 to 90, Lon: -180 to 180'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Updating location...'),
                  duration: Duration(seconds: 1),
                ),
              );

              try {
                await _locationService.updateLocation(restaurant.id, lat, lon);
                await _loadRestaurants();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC23232),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

