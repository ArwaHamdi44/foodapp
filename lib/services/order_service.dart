import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/order.dart' as app_models;

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Place order
  Future<DocumentReference> placeOrder(app_models.Order order) async {
    return await _db.collection('orders').add(order.toMap());
  }

  // Get order by ID
  Future<app_models.Order?> getOrderById(String id) async {
    final doc = await _db.collection('orders').doc(id).get();
    if (!doc.exists) return null;
    return app_models.Order.fromFirestore(doc);
  }

  // Get user orders stream
  Stream<List<app_models.Order>> getUserOrdersStream(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => app_models.Order.fromFirestore(doc))
          .toList();
    });
  }

  // Get user orders (one-time fetch)
  Future<List<app_models.Order>> getUserOrders(String userId) async {
    final snapshot = await _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => app_models.Order.fromFirestore(doc))
        .toList();
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

