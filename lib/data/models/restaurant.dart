import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String image;
  final double? rating;
  final int? reviews;
  final String? address;
  final String? phone;
  final String? description;
  final String? backgroundImage;

  Restaurant({
    required this.id,
    required this.name,
    required this.image,
    this.rating,
    this.reviews,
    this.address,
    this.phone,
    this.description,
    this.backgroundImage,
  });

  // Create from Firestore document
  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      rating: data['rating']?.toDouble(),
      reviews: data['reviews'] as int?,
      address: data['address'] as String?,
      phone: data['phone'] as String?,
      description: data['description'] as String?,
      backgroundImage: data['backgroundImage'] as String?,
    );
  }

  // Create from Map
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      rating: map['rating']?.toDouble(),
      reviews: map['reviews'] as int?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      description: map['description'] as String?,
      backgroundImage: map['backgroundImage'] as String?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      if (rating != null) 'rating': rating,
      if (reviews != null) 'reviews': reviews,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (description != null) 'description': description,
      if (backgroundImage != null) 'backgroundImage': backgroundImage,
    };
  }

  // Create a copy with modified fields
  Restaurant copyWith({
    String? id,
    String? name,
    String? image,
    double? rating,
    int? reviews,
    String? address,
    String? phone,
    String? description,
    String? backgroundImage,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      backgroundImage: backgroundImage ?? this.backgroundImage,
    );
  }
}

