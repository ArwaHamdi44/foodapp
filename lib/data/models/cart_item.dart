class CartItem {
  final String? id; 
  final String foodId;
  final String name;
  final int price;
  final int quantity;
  final String image;
  final String restaurantId;
  final String? restaurantName; 
  final List<String>? selectedAddOns; 

  CartItem({
    this.id,
    required this.foodId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.restaurantId,
    this.restaurantName,
    this.selectedAddOns,
  });

  
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String? ?? map['foodId'] as String?,
      foodId: map['foodId'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] is int
          ? map['price'] as int
          : (map['price'] as num).toInt(),
      quantity: map['quantity'] is int
          ? map['quantity'] as int
          : (map['quantity'] as num).toInt(),
      image: map['image'] ?? '',
      restaurantId: map['restaurantId'] ?? map['restaurant'] ?? '',
      restaurantName: map['restaurant'] as String?,
      selectedAddOns: map['selectedAddOns'] != null
          ? List<String>.from(map['selectedAddOns'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'restaurantId': restaurantId,
      if (restaurantName != null) 'restaurant': restaurantName,
      if (selectedAddOns != null) 'selectedAddOns': selectedAddOns,
    };
  }

  int get totalPrice => price * quantity;

  String get formattedPrice => '$price EGP';

  String get formattedTotalPrice => '$totalPrice EGP';

  CartItem copyWith({
    String? id,
    String? foodId,
    String? name,
    int? price,
    int? quantity,
    String? image,
    String? restaurantId,
    String? restaurantName,
    List<String>? selectedAddOns,
  }) {
    return CartItem(
      id: id ?? this.id,
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

