import 'package:flutter/material.dart';
import '../screens/food_item_screen.dart';
import '../../viewmodels/food_viewmodel.dart';
import '../../data/models/food.dart';

class PopularSection extends StatefulWidget {
  const PopularSection({super.key});

  @override
  State<PopularSection> createState() => _PopularSectionState();
}

class _PopularSectionState extends State<PopularSection> {
  final _foodViewModel = FoodViewModel();
  List<Food>? _popularItems;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPopularFoods();
  }

  Future<void> _loadPopularFoods() async {
    try {
      final popularFoods = await _foodViewModel.getPopularFoods(limit: 3);
      
      if (mounted) {
        setState(() {
          _popularItems = popularFoods;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading popular foods: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Popular',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFC23232),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Text(
                        'Failed to load popular items',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    )
                  : (_popularItems == null || _popularItems!.isEmpty)
                      ? Center(
                          child: Text(
                            'No popular items available',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _popularItems!.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = _popularItems![index];
                            final restaurantName = item.restaurantName ?? 'Unknown';
                            
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FoodItemScreen(
                                      restaurantName: restaurantName,
                                      itemName: item.name,
                                      price: item.formattedPrice,
                                      foodId: item.id,
                                      restaurantId: item.restaurantId,
                                      imageUrl: item.image,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 148,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 148,
                                      height: 148,
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.image,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.fastfood,
                                              size: 60,
                                              color: Color(0xFFC23232),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      restaurantName,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.5),
                                        fontSize: 12,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.formattedPrice,
                                      style: const TextStyle(
                                        color: Color(0xFFC23232),
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
