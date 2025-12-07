import 'package:flutter/material.dart';
import '../components/category_chips.dart';
import '../components/banner_carousel.dart';
import '../components/restaurant_section.dart';
import '../components/popular_section.dart';
import '../components/bottom_nav_bar.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/food_viewmodel.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/food.dart';
import 'restaurant_screen.dart';
import 'food_item_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RestaurantViewModel _restaurantViewModel = RestaurantViewModel();
  final FoodViewModel _foodViewModel = FoodViewModel();
  final TextEditingController _searchController = TextEditingController();

  List<Restaurant> _restaurantResults = [];
  List<Food> _foodResults = [];
  Map<String, String> _restaurantNames = {}; // Map to store restaurant names by ID
  bool _isSearching = false;
  bool _hasSearchQuery = false;
  String _selectedTab = 'All'; // 'All', 'Restaurants', 'Food'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _restaurantResults = [];
        _foodResults = [];
        _hasSearchQuery = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearchQuery = true;
    });

    try {
      final restaurants = await _restaurantViewModel.searchRestaurants(query);
      final allRestaurants = await _restaurantViewModel.getRestaurants();
      
      // Build restaurant name map
      final restaurantNameMap = <String, String>{};
      for (final restaurant in allRestaurants) {
        restaurantNameMap[restaurant.id] = restaurant.name;
      }
      
      // Search foods across all restaurants
      final allFoods = <Food>[];
      for (final restaurant in allRestaurants) {
        try {
          final foods = await _foodViewModel.searchFoods(restaurant.id, query);
          allFoods.addAll(foods);
        } catch (e) {
          // Continue if error
        }
      }

      if (mounted) {
        setState(() {
          _restaurantResults = restaurants;
          _foodResults = allFoods;
          _restaurantNames = restaurantNameMap;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearchQuery = false;
      _restaurantResults = [];
      _foodResults = [];
      _restaurantNames = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 48,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search restaurants or food...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF828282),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF828282),
                            size: 24,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (value.isNotEmpty) {
                            _performSearch(value);
                          } else {
                            _clearSearch();
                          }
                        },
                        onSubmitted: _performSearch,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tab selector (only show when searching)
                  if (_hasSearchQuery)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 'All';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 'All' ? const Color(0xFFC23232) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'All',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedTab == 'All' ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 'Restaurants';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 'Restaurants' ? const Color(0xFFC23232) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Restaurants (${_restaurantResults.length})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedTab == 'Restaurants' ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 'Food';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 'Food' ? const Color(0xFFC23232) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Food (${_foodResults.length})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedTab == 'Food' ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Content
                  Expanded(
                    child: _isSearching
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFC23232),
                            ),
                          )
                        : _hasSearchQuery
                            ? _buildSearchResults()
                            : _buildHomeContent(),
                  ),
                ],
              ),
            ),
            const BottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const CategoryChips(),
          const SizedBox(height: 16),
          const BannerCarousel(),
          const SizedBox(height: 20),
          const RestaurantSection(),
          const SizedBox(height: 20),
          const PopularSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_selectedTab == 'Restaurants') {
      return _buildRestaurantResults();
    } else if (_selectedTab == 'Food') {
      return _buildFoodResults();
    } else {
      // All tab
      if (_restaurantResults.isEmpty && _foodResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'No results found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_restaurantResults.isNotEmpty) ...[
            const Text(
              'Restaurants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._restaurantResults.map((restaurant) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRestaurantItem(restaurant),
            )),
            const SizedBox(height: 24),
          ],
          if (_foodResults.isNotEmpty) ...[
            const Text(
              'Food',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._foodResults.map((food) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFoodItem(food),
            )),
          ],
        ],
      );
    }
  }

  Widget _buildRestaurantResults() {
    if (_restaurantResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No restaurants found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _restaurantResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildRestaurantItem(_restaurantResults[index]),
    );
  }

  Widget _buildFoodResults() {
    if (_foodResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No food items found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _foodResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildFoodItem(_foodResults[index]),
    );
  }

  Widget _buildRestaurantItem(Restaurant restaurant) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantScreen(restaurantId: restaurant.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6E6)),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF5F5F5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
                  if (restaurant.rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.rating}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(Food food) {
    // Get restaurant name from the map
    final restaurantName = _restaurantNames[food.restaurantId] ?? food.restaurantId;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodItemScreen(
              restaurantName: restaurantName,
              itemName: food.name,
              price: '${food.price} EGP',
              foodId: food.id,
              restaurantId: food.restaurantId,
              imageUrl: food.image,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6E6)),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF5F5F5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  food.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.fastfood,
                      size: 40,
                      color: Color(0xFFC23232),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food.price} EGP',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC23232),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}