import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user.dart' as app_user;
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Validation methods
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null; 
  }

  String? validateName(String name, String fieldName) {
    if (name.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    if (name.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null; 
  }

  Future<app_user.User> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      
      if (!isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      
      final passwordError = validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Login failed: User is null');
      }

      final userProfile = await _userService.getUserProfile(credential.user!.uid);

      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      return userProfile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<app_user.User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
    
      if (!isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      
      final passwordError = validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

    
      final firstNameError = validateName(firstName, 'First name');
      if (firstNameError != null) {
        throw Exception(firstNameError);
      }

      
      final lastNameError = validateName(lastName, 'Last name');
      if (lastNameError != null) {
        throw Exception(lastNameError);
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign up failed: User is null');
      }

      final userId = credential.user!.uid;

      final userProfile = app_user.User(
        id: userId,
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        createdAt: DateTime.now(),
      );

      await _userService.createUserProfile(userProfile);

      return userProfile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }

  Future<app_user.User?> getUserProfile(String userId) async {
    try {
      return await _userService.getUserProfile(userId);
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }
}