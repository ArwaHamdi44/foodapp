import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String name;
  final int price; 
  final String image;
  final double? rating;
  final int? reviews;
  final String? description;
  final List<String>? addOns;
  final bool? isAvailable;

  Food({
    required this.id,
    required this.restaurantName,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.image,
    this.rating,
    this.reviews,
    this.description,
    this.addOns,
    this.isAvailable,
  });

  // Create from Firestore document
  factory Food.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Food(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      image: data['image'] ?? '',
      rating: data['rating']?.toDouble(),
      reviews: data['reviews'] as int?,
      description: data['description'] as String?,
      addOns: data['addOns'] != null
          ? List<String>.from(data['addOns'])
          : null,
      isAvailable: data['isAvailable'] as bool?,
    );
  }

  // Create from Map
  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      image: map['image'] ?? '',
      rating: map['rating']?.toDouble(),
      reviews: map['reviews'] as int?,
      description: map['description'] as String?,
      addOns: map['addOns'] != null
          ? List<String>.from(map['addOns'])
          : null,
      isAvailable: map['isAvailable'] as bool?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'price': price,
      'image': image,
      if (rating != null) 'rating': rating,
      if (reviews != null) 'reviews': reviews,
      if (description != null) 'description': description,
      if (addOns != null) 'addOns': addOns,
      if (isAvailable != null) 'isAvailable': isAvailable,
    };
  }

  // Format price as string
  String get formattedPrice => '$price EGP';

  // Create a copy with modified fields
  Food copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? name,
    int? price,
    String? image,
    double? rating,
    int? reviews,
    String? description,
    List<String>? addOns,
    bool? isAvailable,
  }) {
    return Food(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      description: description ?? this.description,
      addOns: addOns ?? this.addOns,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

