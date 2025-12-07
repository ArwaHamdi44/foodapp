import 'package:flutter/material.dart';
import 'food_item_screen.dart';
import '../components/bottom_nav_bar.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../viewmodels/food_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../services/auth_service.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/food.dart';

class RestaurantScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final _restaurantViewModel = RestaurantViewModel();
  final _foodViewModel = FoodViewModel();
  final _userViewModel = UserViewModel();
  final _authService = AuthService();
  
  Restaurant? _restaurant;
  List<Food>? _foods;
  Set<String> _favoriteFoodIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('Loading restaurant with ID: ${widget.restaurantId}');
      
      // Load restaurant data
      final restaurant = await _restaurantViewModel.getRestaurantById(widget.restaurantId);
      print('Restaurant loaded: ${restaurant?.name}');
      
      // Load foods for this restaurant
      final foods = await _foodViewModel.getFoodsByRestaurant(widget.restaurantId);
      print('Foods found: ${foods.length}');
      
      // Load user's favorite food IDs
      Set<String> favoriteFoodIds = {};
      if (_authService.currentUserId != null) {
        try {
          final favoriteIds = await _userViewModel.getFavoriteFoodIds();
          favoriteFoodIds = Set.from(favoriteIds);
        } catch (e) {
          print('Error loading favorites: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _restaurant = restaurant;
          _foods = foods;
          _favoriteFoodIds = favoriteFoodIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // <CHANGE> Add method to toggle favorite status
  Future<void> _toggleFavorite(String foodId) async {
    if (_authService.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add favorites'),
          backgroundColor: Color(0xFFC23232),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final isFavorite = _favoriteFoodIds.contains(foodId);
      
      if (isFavorite) {
        // Remove from favorites
        await _userViewModel.removeFavoriteFood(foodId);
        setState(() {
          _favoriteFoodIds.remove(foodId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Add to favorites
        await _userViewModel.addFavoriteFood(foodId);
        setState(() {
          _favoriteFoodIds.add(foodId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFC23232),
          ),
        ),
      );
    }

    if (_error != null || _restaurant == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFC23232),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Color(0xFFC23232),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load restaurant',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadData();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFC23232)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNavBar(),
      body: Column(
        children: [
          // ... existing code ...
          Container(
            height: 280,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  _restaurant!.backgroundImage ?? 
                  'https://images.mindtrip.ai/restaurants/e235/7ea5/1c55/782f/3378/9293/ac7a/6dfb',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_border,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // ... existing code ...
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _restaurant!.image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Color(0xFFC23232),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _restaurant!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Menu items from database
          Expanded(
            child: (_foods == null || _foods!.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No menu items available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._foods!.map((food) {
                        final isFavorite = _favoriteFoodIds.contains(food.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6E6E6)),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FoodItemScreen(
                                    restaurantName: _restaurant!.name,
                                    itemName: food.name,
                                    price: '${food.price} EGP',
                                    foodId: food.id,
                                    restaurantId: _restaurant!.id,
                                    imageUrl: food.image,
                                  ),
                                ),
                              );
                            },
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
                                      food.image ?? 'https://t4.ftcdn.net/jpg/02/02/48/35/360_F_202483549_3cDh8uaQ5OJG9GUDsp9YKSQNt69rjucc.jpg',
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
                                        _restaurant!.name,
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
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (food.rating != null)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Color(0xFFFFC107),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${food.rating}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (food.reviews != null) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${food.reviews} ratings)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black.withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${food.price} EGP',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFC23232),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // <CHANGE> Updated favorite button with dynamic state and filled/outlined icons
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: const Color(0xFFC23232),
                                        size: 22,
                                      ),
                                      onPressed: () => _toggleFavorite(food.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}