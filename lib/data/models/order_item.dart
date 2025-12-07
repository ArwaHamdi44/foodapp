import 'cart_item.dart';

class OrderItem {
  final String foodId;
  final String name;
  final int price;
  final int quantity;
  final String image;
  final String restaurantId;
  final String? restaurantName;
  final List<String>? selectedAddOns;

  OrderItem({
    required this.foodId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.restaurantId,
    this.restaurantName,
    this.selectedAddOns,
  });

  // Create from Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      foodId: map['foodId'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] is int
          ? map['price'] as int
          : (map['price'] as num).toInt(),
      quantity: map['quantity'] is int
          ? map['quantity'] as int
          : (map['quantity'] as num).toInt(),
      image: map['image'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'],
      selectedAddOns: map['selectedAddOns'] != null
          ? List<String>.from(map['selectedAddOns'])
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      if (selectedAddOns != null) 'selectedAddOns': selectedAddOns,
    };
  }

  // Calculate total price for this item
  int get totalPrice => price * quantity;

  // Format price as string
  String get formattedPrice => '$price EGP';

  // Format total price as string
  String get formattedTotalPrice => '$totalPrice EGP';

  // Create from CartItem (for converting cart to order)
  factory OrderItem.fromCartItem(CartItem cartItem) {
    return OrderItem(
      foodId: cartItem.foodId,
      name: cartItem.name,
      price: cartItem.price,
      quantity: cartItem.quantity,
      image: cartItem.image,
      restaurantId: cartItem.restaurantId,
      restaurantName: cartItem.restaurantName,
      selectedAddOns: cartItem.selectedAddOns,
    );
  }

  // Create a copy with modified fields
  OrderItem copyWith({
    String? foodId,
    String? name,
    int? price,
    int? quantity,
    String? image,
    String? restaurantId,
    String? restaurantName,
    List<String>? selectedAddOns,
  }) {
    return OrderItem(
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      selectedAddOns: selectedAddOns ?? this.selectedAddOns,
    );
  }
}

