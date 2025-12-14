import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; 
  final String? phone;
  final String? profileImageUrl;
  final List<String>? savedAddresses;
  final List<String>? favoriteFoodIds;
  final List<String>? favoriteRestaurantIds;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'user', 
    this.phone,
    this.profileImageUrl,
    this.savedAddresses,
    this.favoriteFoodIds,
    this.favoriteRestaurantIds,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  
  bool get isAdmin => role == 'admin';

  String get fullName => '$firstName $lastName';

  String get displayName => firstName;

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
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? map['first_name'] ?? '',
      lastName: map['lastName'] ?? map['last_name'] ?? '',
      role: map['role'] ?? 'user', 
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
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

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
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toPublicMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }

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
    double? latitude,
    double? longitude,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  User addAddress(String address) {
    final addresses = savedAddresses ?? [];
    if (!addresses.contains(address)) {
      return copyWith(savedAddresses: [...addresses, address]);
    }
    return this;
  }

  User removeAddress(String address) {
    final addresses = savedAddresses ?? [];
    return copyWith(
      savedAddresses: addresses.where((a) => a != address).toList(),
    );
  }

  bool get hasSavedAddresses => 
      savedAddresses != null && savedAddresses!.isNotEmpty;

  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  User addFavoriteFood(String foodId) {
    final favorites = favoriteFoodIds ?? [];
    if (!favorites.contains(foodId)) {
      return copyWith(favoriteFoodIds: [...favorites, foodId]);
    }
    return this;
  }

  User removeFavoriteFood(String foodId) {
    final favorites = favoriteFoodIds ?? [];
    return copyWith(
      favoriteFoodIds: favorites.where((id) => id != foodId).toList(),
    );
  }

  bool isFavoriteFood(String foodId) {
    return favoriteFoodIds?.contains(foodId) ?? false;
  }

  User addFavoriteRestaurant(String restaurantId) {
    final favorites = favoriteRestaurantIds ?? [];
    if (!favorites.contains(restaurantId)) {
      return copyWith(favoriteRestaurantIds: [...favorites, restaurantId]);
    }
    return this;
  }

  User removeFavoriteRestaurant(String restaurantId) {
    final favorites = favoriteRestaurantIds ?? [];
    return copyWith(
      favoriteRestaurantIds: favorites.where((id) => id != restaurantId).toList(),
    );
  }

  bool isFavoriteRestaurant(String restaurantId) {
    return favoriteRestaurantIds?.contains(restaurantId) ?? false;
  }
}

