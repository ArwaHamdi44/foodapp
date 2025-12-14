import 'package:flutter/material.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/food_viewmodel.dart';
import '../../data/models/cart_item.dart';
import '../../services/auth_service.dart';
import 'cart_screen.dart';

class FoodItemScreen extends StatefulWidget {
  final String restaurantName;
  final String itemName;
  final String price;
  final String? foodId; 
  final String? restaurantId; 
  final String? imageUrl; 

  const FoodItemScreen({
    super.key,
    required this.restaurantName,
    required this.itemName,
    required this.price,
    this.foodId,
    this.restaurantId,
    this.imageUrl,
  });

  @override
  State<FoodItemScreen> createState() => _FoodItemScreenState();
}

class _FoodItemScreenState extends State<FoodItemScreen> {
  List<String> addOns = ['Onion', 'Barbeque sauce', 'Garlic sauce'];
  List<bool> selectedAddOns = [false, false, false];
  final CartViewModel _cartViewModel = CartViewModel();
  final UserViewModel _userViewModel = UserViewModel();
  final FoodViewModel _foodViewModel = FoodViewModel();
  final AuthService _authService = AuthService();
  bool _isAddingToCart = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  bool _isLoadingAddOns = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadAddOns();
  }

  Future<void> _loadAddOns() async {
    final foodId = widget.foodId;
    if (foodId != null && foodId.isNotEmpty) {
      try {
        final fetchedAddOns = await _foodViewModel.getAddOnsForFood(foodId);
        if (mounted) {
          setState(() {
            if (fetchedAddOns.isNotEmpty) {
              addOns = fetchedAddOns;
              selectedAddOns = List.generate(addOns.length, (_) => false);
            }
            _isLoadingAddOns = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingAddOns = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingAddOns = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final foodId = _getFoodId();
    if (foodId != null && _authService.currentUserId != null) {
      try {
        final isFav = await _userViewModel.isFavoriteFood(foodId);
        if (mounted) {
          setState(() {
            _isFavorite = isFav;
          });
        }
      } catch (e) {
      }
    }
  }

  String? _getFoodId() {
    if (widget.foodId != null && widget.foodId!.isNotEmpty) {
      return widget.foodId;
    }

    return '${widget.restaurantName}_${widget.itemName}'.toLowerCase().replaceAll(' ', '_');
  }

  Future<void> _toggleFavorite() async {
    if (_authService.currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final foodId = _getFoodId();
    if (foodId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot add to favorites: Food ID not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      if (_isFavorite) {
        await _userViewModel.removeFavoriteFood(foodId);
      } else {
        await _userViewModel.addFavoriteFood(foodId);
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoadingFavorite = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _parsePrice(String priceString) {
    final priceStr = priceString.replaceAll(' EGP', '').trim();
    return int.tryParse(priceStr) ?? 0;
  }

  Future<void> _addToCart() async {
    if (_authService.currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add items to cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final selectedAddOnsList = <String>[];
      for (int i = 0; i < addOns.length; i++) {
        if (selectedAddOns[i]) {
          selectedAddOnsList.add(addOns[i]);
        }
      }

      final cartItem = CartItem(
        foodId: widget.foodId ?? widget.itemName.toLowerCase().replaceAll(' ', '_'),
        name: widget.itemName,
        price: _parsePrice(widget.price),
        quantity: 1,
        image: widget.imageUrl ?? 'https://t4.ftcdn.net/jpg/02/02/48/35/360_F_202483549_3cDh8uaQ5OJG9GUDsp9YKSQNt69rjucc.jpg',
        restaurantId: widget.restaurantId ?? widget.restaurantName.toLowerCase().replaceAll(' ', '_'),
        restaurantName: widget.restaurantName,
        selectedAddOns: selectedAddOnsList.isNotEmpty ? selectedAddOnsList : null,
      );

      await _cartViewModel.addToCart(cartItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added to cart!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CartScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodImageUrl = widget.imageUrl ?? 
        'https://t4.ftcdn.net/jpg/02/02/48/35/360_F_202483549_3cDh8uaQ5OJG9GUDsp9YKSQNt69rjucc.jpg';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(foodImageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
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
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: _isLoadingFavorite
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: _isFavorite ? Colors.red : Colors.white,
                                    size: 20,
                                  ),
                          ),
                          onPressed: _toggleFavorite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _isLoadingAddOns
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFC23232),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            widget.itemName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.price,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC23232),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'A delicious ${widget.itemName} made with premium ingredients, shredded mozzarella cheese, and slices of pepperoni, a spicy, savory American salami made from cured pork and beef.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black.withOpacity(0.7),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Add ons',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(addOns.length, (index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedAddOns[index]
                                      ? const Color(0xFFC23232)
                                      : const Color(0xFFE6E6E6),
                                  width: selectedAddOns[index] ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedAddOns[index] = !selectedAddOns[index];
                                  });
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      addOns[index],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: selectedAddOns[index]
                                            ? const Color(0xFFC23232)
                                            : Colors.white,
                                        border: Border.all(
                                          color: selectedAddOns[index]
                                              ? const Color(0xFFC23232)
                                              : const Color(0xFFCCCCCC),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: selectedAddOns[index]
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 100),
                        ],
                      ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isAddingToCart ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC23232),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isAddingToCart
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}