// Updated User Model with role attribute
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'user' or 'admin'
  final String? phone;
  final String? profileImageUrl;
  final List<String>? savedAddresses;
  final List<String>? favoriteFoodIds;
  final List<String>? favoriteRestaurantIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'user', // Default to 'user'
    this.phone,
    this.profileImageUrl,
    this.savedAddresses,
    this.favoriteFoodIds,
    this.favoriteRestaurantIds,
    this.createdAt,
    this.updatedAt,
  });

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Get full name
  String get fullName => '$firstName $lastName';

  // Get display name (first name only)
  String get displayName => firstName;

  // Create from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? data['first_name'] ?? '',
      lastName: data['lastName'] ?? data['last_name'] ?? '',
      role: data['role'] ?? 'user', // Default to 'user' if not set
      phone: data['phone'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      savedAddresses: data['savedAddresses'] != null
          ? List<String>.from(data['savedAddresses'])
          : null,
      favoriteFoodIds: data['favoriteFoodIds'] != null
          ? List<String>.from(data['favoriteFoodIds'])
          : null,
      favoriteRestaurantIds: data['favoriteRestaurantIds'] != null
          ? List<String>.from(data['favoriteRestaurantIds'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? map['first_name'] ?? '',
      lastName: map['lastName'] ?? map['last_name'] ?? '',
      role: map['role'] ?? 'user', // Default to 'user' if not set
      phone: map['phone'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      savedAddresses: map['savedAddresses'] != null
          ? List<String>.from(map['savedAddresses'])
          : null,
      favoriteFoodIds: map['favoriteFoodIds'] != null
          ? List<String>.from(map['favoriteFoodIds'])
          : null,
      favoriteRestaurantIds: map['favoriteRestaurantIds'] != null
          ? List<String>.from(map['favoriteRestaurantIds'])
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      if (phone != null) 'phone': phone,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (savedAddresses != null) 'savedAddresses': savedAddresses,
      if (favoriteFoodIds != null) 'favoriteFoodIds': favoriteFoodIds,
      if (favoriteRestaurantIds != null) 'favoriteRestaurantIds': favoriteRestaurantIds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to Map excluding sensitive data (for public display)
  Map<String, dynamic> toPublicMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }

  // Create a copy with modified fields
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? phone,
    String? profileImageUrl,
    List<String>? savedAddresses,
    List<String>? favoriteFoodIds,
    List<String>? favoriteRestaurantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      favoriteFoodIds: favoriteFoodIds ?? this.favoriteFoodIds,
      favoriteRestaurantIds: favoriteRestaurantIds ?? this.favoriteRestaurantIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Add a saved address
  User addAddress(String address) {
    final addresses = savedAddresses ?? [];
    if (!addresses.contains(address)) {
      return copyWith(savedAddresses: [...addresses, address]);
    }
    return this;
  }

  // Remove a saved address
  User removeAddress(String address) {
    final addresses = savedAddresses ?? [];
    return copyWith(
      savedAddresses: addresses.where((a) => a != address).toList(),
    );
  }

  // Check if user has saved addresses
  bool get hasSavedAddresses => 
      savedAddresses != null && savedAddresses!.isNotEmpty;

  // Get initials for avatar display
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  // Add favorite food
  User addFavoriteFood(String foodId) {
    final favorites = favoriteFoodIds ?? [];
    if (!favorites.contains(foodId)) {
      return copyWith(favoriteFoodIds: [...favorites, foodId]);
    }
    return this;
  }

  // Remove favorite food
  User removeFavoriteFood(String foodId) {
    final favorites = favoriteFoodIds ?? [];
    return copyWith(
      favoriteFoodIds: favorites.where((id) => id != foodId).toList(),
    );
  }

  // Check if food is favorite
  bool isFavoriteFood(String foodId) {
    return favoriteFoodIds?.contains(foodId) ?? false;
  }

  // Add favorite restaurant
  User addFavoriteRestaurant(String restaurantId) {
    final favorites = favoriteRestaurantIds ?? [];
    if (!favorites.contains(restaurantId)) {
      return copyWith(favoriteRestaurantIds: [...favorites, restaurantId]);
    }
    return this;
  }

  // Remove favorite restaurant
  User removeFavoriteRestaurant(String restaurantId) {
    final favorites = favoriteRestaurantIds ?? [];
    return copyWith(
      favoriteRestaurantIds: favorites.where((id) => id != restaurantId).toList(),
    );
  }

  // Check if restaurant is favorite
  bool isFavoriteRestaurant(String restaurantId) {
    return favoriteRestaurantIds?.contains(restaurantId) ?? false;
  }
}

