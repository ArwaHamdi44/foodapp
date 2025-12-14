import '../services/order_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../data/models/order.dart';
import '../data/models/order_item.dart';

class OrderViewModel {
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();

  Stream<List<Order>> getUserOrdersStream() {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return _orderService.getUserOrdersStream(userId);
  }

  Future<List<Order>> getUserOrders() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    try {
      return await _orderService.getUserOrders(userId);
    } catch (e) {
      throw Exception('Failed to fetch orders: ${e.toString()}');
    }
  }

  Future<Order?> getOrderById(String id) async {
    try {
      return await _orderService.getOrderById(id);
    } catch (e) {
      throw Exception('Failed to fetch order: ${e.toString()}');
    }
  }

  Future<Order> placeOrderFromCart({
    required String address,
    required String paymentMethod,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
     
      final cart = await _cartService.getCart(userId);
      if (cart == null || cart.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      final orderItems = cart.items.map((item) => OrderItem.fromCartItem(item)).toList();

    
      final order = Order(
        id: '', 
        userId: userId,
        items: orderItems,
        total: cart.total,
        address: address,
        paymentMethod: paymentMethod,
        deliveryFee: cart.deliveryFee,
        taxes: cart.taxes,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      
      final docRef = await _orderService.placeOrder(order);
      
      final placedOrder = order.copyWith(id: docRef.id);

      await _cartService.clearCart(userId);

      return placedOrder;
    } catch (e) {
      throw Exception('Failed to place order: ${e.toString()}');
    }
  }

  Future<Order> placeOrder({
    required List<OrderItem> items,
    required int subtotal,
    required String address,
    required String paymentMethod,
    int deliveryFee = 20,
    int taxes = 10,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final total = subtotal + deliveryFee + taxes;

      final order = Order(
        id: '',
        userId: userId,
        items: items,
        total: total,
        address: address,
        paymentMethod: paymentMethod,
        deliveryFee: deliveryFee,
        taxes: taxes,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _orderService.placeOrder(order);
      return order.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to place order: ${e.toString()}');
    }
  }

  
  Future<void> cancelOrder(String orderId) async {
    try {
      final order = await _orderService.getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (!order.canCancel) {
        throw Exception('Order cannot be cancelled');
      }

      await _orderService.updateOrderStatus(orderId, OrderStatus.cancelled.toString().split('.').last);
    } catch (e) {
      throw Exception('Failed to cancel order: ${e.toString()}');
    }
  }

  Future<List<Order>> getPendingOrders() async {
    try {
      final orders = await getUserOrders();
      return orders.where((order) => order.status == OrderStatus.pending).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending orders: ${e.toString()}');
    }
  }
}

