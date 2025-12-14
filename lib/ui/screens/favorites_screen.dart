import 'package:flutter/material.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/food_viewmodel.dart';
import '../../viewmodels/restaurant_viewmodel.dart';
import '../../services/auth_service.dart';
import '../../data/models/food.dart';
import 'food_item_screen.dart';
import '../components/bottom_nav_bar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final UserViewModel _userViewModel = UserViewModel();
  final FoodViewModel _foodViewModel = FoodViewModel();
  final RestaurantViewModel _restaurantViewModel = RestaurantViewModel();
  final AuthService _authService = AuthService();

  List<Food> _favoriteFoods = [];
  Map<String, String> _restaurantNames = {}; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_authService.currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final favoriteFoodIds = await _userViewModel.getFavoriteFoodIds();

      final foods = <Food>[];
      final restaurantNamesMap = <String, String>{};
      
      for (final foodId in favoriteFoodIds) {
        try {
          final food = await _foodViewModel.getFoodById(foodId);
          if (food != null) {
            foods.add(food);
            if (!restaurantNamesMap.containsKey(food.restaurantId)) {
              try {
                final restaurant = await _restaurantViewModel.getRestaurantById(food.restaurantId);
                if (restaurant != null) {
                  restaurantNamesMap[food.restaurantId] = restaurant.name;
                }
              } catch (e) {
                
              }
            }
          }
        } catch (e) {
          
        }
      }

      if (mounted) {
        setState(() {
          _favoriteFoods = foods;
          _restaurantNames = restaurantNamesMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load favorites: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFavoriteFood(String foodId) async {
    try {
      await _userViewModel.removeFavoriteFood(foodId);
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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
    if (_authService.currentUserId == null) {
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
            'My Favorites',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFFC23232),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please log in',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to view your favorites',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.5),
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
              'My Favorites',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Items you love',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteFoods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorite foods yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start adding foods to your favorites',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteFoods.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final food = _favoriteFoods[index];
                    return Container(
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
                                restaurantName: _restaurantNames[food.restaurantId] ?? food.restaurantId,
                                itemName: food.name,
                                price: '${food.price} EGP',
                                foodId: food.id,
                                restaurantId: food.restaurantId,
                                imageUrl: food.image,
                              ),
                            ),
                          ).then((_) => _loadFavorites());
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
                                    _restaurantNames[food.restaurantId] ?? food.restaurantId,
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
                                  Text(
                                    '${food.price} EGP',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC23232),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC23232),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onPressed: () => _removeFavoriteFood(food.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
