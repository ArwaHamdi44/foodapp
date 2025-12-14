import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/cart.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Cart?> getCartStream(String userId) {
    return _db.collection('carts').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Cart.fromFirestore(snapshot);
    });
  }

  Future<Cart?> getCart(String userId) async {
    final doc = await _db.collection('carts').doc(userId).get();
    if (!doc.exists) return null;
    return Cart.fromFirestore(doc);
  }

  Future<void> saveCart(Cart cart) async {
    await _db.collection('carts').doc(cart.userId).set(cart.toMap());
  }


  Future<void> clearCart(String userId) async {
    await _db.collection('carts').doc(userId).delete();
  }
}

