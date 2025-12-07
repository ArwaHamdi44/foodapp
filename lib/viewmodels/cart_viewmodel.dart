import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../data/models/cart.dart';
import '../data/models/cart_item.dart';

class CartViewModel {
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();

  // Get cart stream for current user
  Stream<Cart?> getCartStream() {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return _cartService.getCartStream(userId);
  }

  // Get cart (one-time fetch)
  Future<Cart?> getCart() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    try {
      return await _cartService.getCart(userId);
    } catch (e) {
      throw Exception('Failed to fetch cart: ${e.toString()}');
    }
  }

  // Add item to cart
  Future<void> addToCart(CartItem item) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentCart = await _cartService.getCart(userId);
      
      List<CartItem> items;
      if (currentCart != null) {
        items = List<CartItem>.from(currentCart.items);
        
        // Check if item already exists, update quantity if same foodId
        final existingIndex = items.indexWhere((i) => i.foodId == item.foodId);
        if (existingIndex != -1) {
          items[existingIndex] = items[existingIndex].copyWith(
            quantity: items[existingIndex].quantity + item.quantity,
          );
        } else {
          items.add(item);
        }
      } else {
        items = [item];
      }

      final subtotal = _calculateSubtotal(items);
      final cart = Cart(
        userId: userId,
        items: items,
        subtotal: subtotal,
        deliveryFee: 20,
        taxes: 10,
      );

      await _cartService.saveCart(cart);
    } catch (e) {
      throw Exception('Failed to add item to cart: ${e.toString()}');
    }
  }

  // Update item quantity in cart
  Future<void> updateItemQuantity(String foodId, int quantity) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentCart = await _cartService.getCart(userId);
      if (currentCart == null) {
        throw Exception('Cart not found');
      }

      final items = List<CartItem>.from(currentCart.items);
      final index = items.indexWhere((item) => item.foodId == foodId);
      
      if (index == -1) {
        throw Exception('Item not found in cart');
      }

      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: quantity);
      }

      final subtotal = _calculateSubtotal(items);
      final cart = Cart(
        userId: userId,
        items: items,
        subtotal: subtotal,
        deliveryFee: currentCart.deliveryFee,
        taxes: currentCart.taxes,
      );

      await _cartService.saveCart(cart);
    } catch (e) {
      throw Exception('Failed to update item quantity: ${e.toString()}');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String foodId) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final currentCart = await _cartService.getCart(userId);
      if (currentCart == null) {
        throw Exception('Cart not found');
      }

      final items = currentCart.items.where((item) => item.foodId != foodId).toList();
      final subtotal = _calculateSubtotal(items);
      
      final cart = Cart(
        userId: userId,
        items: items,
        subtotal: subtotal,
        deliveryFee: currentCart.deliveryFee,
        taxes: currentCart.taxes,
      );

      await _cartService.saveCart(cart);
    } catch (e) {
      throw Exception('Failed to remove item from cart: ${e.toString()}');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _cartService.clearCart(userId);
    } catch (e) {
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }

  // Calculate subtotal from items
  int _calculateSubtotal(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Get cart item count
  Future<int> getCartItemCount() async {
    final cart = await getCart();
    if (cart == null) return 0;
    return cart.totalItems;
  }
}

