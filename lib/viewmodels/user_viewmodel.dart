import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../data/models/user.dart';

class UserViewModel {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  // Get current user profile
  Future<User?> getCurrentUserProfile() async {
    final userId = _authService.currentUserId;
    if (userId == null) return null;
    try {
      return await _userService.getUserProfile(userId);
    } catch (e) {
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  // Get current user profile stream
  Stream<User?> getCurrentUserProfileStream() {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }
    return _userService.getUserProfileStream(userId);
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentProfile = await _userService.getUserProfile(userId);
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = currentProfile.copyWith(
        firstName: firstName ?? currentProfile.firstName,
        lastName: lastName ?? currentProfile.lastName,
        phone: phone ?? currentProfile.phone,
        profileImageUrl: profileImageUrl ?? currentProfile.profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await _userService.updateUserProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  // Add saved address
  Future<void> addSavedAddress(String address) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentProfile = await _userService.getUserProfile(userId);
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = currentProfile.addAddress(address);
      await _userService.updateUserProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to add address: ${e.toString()}');
    }
  }

  // Remove saved address
  Future<void> removeSavedAddress(String address) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentProfile = await _userService.getUserProfile(userId);
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = currentProfile.removeAddress(address);
      await _userService.updateUserProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to remove address: ${e.toString()}');
    }
  }

  // Get saved addresses
  Future<List<String>> getSavedAddresses() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.savedAddresses ?? [];
    } catch (e) {
      throw Exception('Failed to fetch saved addresses: ${e.toString()}');
    }
  }

  // Add favorite food
  Future<void> addFavoriteFood(String foodId) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentProfile = await _userService.getUserProfile(userId);
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = currentProfile.addFavoriteFood(foodId);
      await _userService.updateUserProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to add favorite food: ${e.toString()}');
    }
  }

  // Remove favorite food
  Future<void> removeFavoriteFood(String foodId) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentProfile = await _userService.getUserProfile(userId);
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = currentProfile.removeFavoriteFood(foodId);
      await _userService.updateUserProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to remove favorite food: ${e.toString()}');
    }
  }

  // Check if food is favorite
  Future<bool> isFavoriteFood(String foodId) async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.isFavoriteFood(foodId) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Add favorite restaurant
  Future<void> addFavoriteRestaurant(String restaurantId) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentProfile = await _userService.getUserProfile(userId);
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = currentProfile.addFavoriteRestaurant(restaurantId);
      await _userService.updateUserProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to add favorite restaurant: ${e.toString()}');
    }
  }

  // Remove favorite restaurant
  Future<void> removeFavoriteRestaurant(String restaurantId) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentProfile = await _userService.getUserProfile(userId);
      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = currentProfile.removeFavoriteRestaurant(restaurantId);
      await _userService.updateUserProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to remove favorite restaurant: ${e.toString()}');
    }
  }

  // Check if restaurant is favorite
  Future<bool> isFavoriteRestaurant(String restaurantId) async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.isFavoriteRestaurant(restaurantId) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get favorite food IDs
  Future<List<String>> getFavoriteFoodIds() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.favoriteFoodIds ?? [];
    } catch (e) {
      throw Exception('Failed to fetch favorite foods: ${e.toString()}');
    }
  }

  // Get favorite restaurant IDs
  Future<List<String>> getFavoriteRestaurantIds() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.favoriteRestaurantIds ?? [];
    } catch (e) {
      throw Exception('Failed to fetch favorite restaurants: ${e.toString()}');
    }
  }
}

