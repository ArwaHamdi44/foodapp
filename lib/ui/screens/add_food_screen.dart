import 'package:flutter/material.dart';
import '../../viewmodels/food_viewmodel.dart';
import '../../data/models/food.dart';

class AdminAddFoodScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const AdminAddFoodScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<AdminAddFoodScreen> createState() => _AdminAddFoodScreenState();
}

class _AdminAddFoodScreenState extends State<AdminAddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodViewModel = FoodViewModel();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController;
  late TextEditingController _addOnsController;

  // NEW
  late TextEditingController _ratingController;
  late TextEditingController _reviewsController;

  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _imageController = TextEditingController();
    _descriptionController = TextEditingController();
    _addOnsController = TextEditingController();
    _ratingController = TextEditingController();
    _reviewsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    _addOnsController.dispose();

    // NEW
    _ratingController.dispose();
    _reviewsController.dispose();

    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final addOns = _addOnsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final food = Food(
        id: '',
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        name: _nameController.text,
        price: int.parse(_priceController.text),
        image: _imageController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        addOns: addOns.isNotEmpty ? addOns : null,

        // NEW
        rating: _ratingController.text.isNotEmpty
            ? double.parse(_ratingController.text)
            : null,
        reviews: _reviewsController.text.isNotEmpty
            ? int.parse(_reviewsController.text)
            : null,

        isAvailable: _isAvailable,
      );

      final foodId = await _foodViewModel.addFood(food);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food item added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _nameController.clear();
      _priceController.clear();
      _imageController.clear();
      _descriptionController.clear();
      _addOnsController.clear();

      // NEW
      _ratingController.clear();
      _reviewsController.clear();

      setState(() {
        _isAvailable = true;
      });

      Navigator.pop(context, foodId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFC23232),
        title: Text(
          'Add Food Item - ${widget.restaurantName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // NAME
              const Text('Food Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter a food name' : null,
              ),
              const SizedBox(height: 20),

              // PRICE
              const Text('Price (EGP)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Enter price';
                  if (int.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // IMAGE
              const Text('Image URL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageController,
                validator: (v) {
                  if (v!.isEmpty) return 'Enter image URL';
                  if (!v.startsWith('http')) return 'Invalid URL';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // DESCRIPTION
              const Text('Description (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // ADD ONS
              const Text('Add-ons (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addOnsController,
                maxLines: 2,
                decoration:
                    const InputDecoration(helperText: 'Separate with commas'),
              ),
              const SizedBox(height: 20),

              // ⭐ NEW: RATING
              const Text('Rating (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ratingController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return null;
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 5) {
                    return 'Rating must be 0 - 5';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 📝 NEW: REVIEWS
              const Text('Number of Reviews (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reviewsController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return null;
                  if (int.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // SWITCH
              SwitchListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (value) =>
                    setState(() => _isAvailable = value),
              ),

              const SizedBox(height: 30),

              // SUBMIT
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC23232),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Food Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
