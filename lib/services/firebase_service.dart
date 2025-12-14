import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getRestaurants() {
    return _db.collection('restaurants').snapshots().map((snap) =>
        snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<List<Map<String, dynamic>>> getFoodsByRestaurant(String restaurantId) async {
    final snap = await _db
        .collection('foods')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> saveCart(String userId, List<Map<String, dynamic>> items, int subtotal) async {
    final cartRef = _db.collection('carts').doc(userId);
    await cartRef.set({
      'items': items,
      'subtotal': subtotal,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> cartStream(String userId) {
    final ref = _db.collection('carts').doc(userId);
    return ref.snapshots().map((snap) => snap.exists ? snap.data() as Map<String, dynamic> : null);
  }

  Future<DocumentReference> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required int total,
    required String address,
    required String paymentMethod,
    required int deliveryFee,
    required int taxes,
  }) async {
    final ordersRef = _db.collection('orders');
    final orderData = {
      'userId': userId,
      'items': items,
      'total': total,
      'address': address,
      'paymentMethod': paymentMethod,
      'deliveryFee': deliveryFee,
      'taxes': taxes,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    final docRef = await ordersRef.add(orderData);
    await _db.collection('carts').doc(userId).delete().catchError((_) {});
    return docRef;
  }
}
