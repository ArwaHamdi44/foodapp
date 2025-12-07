import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class Cart {
  final String userId; // Document ID in Firestore
  final List<CartItem> items;
  final int subtotal;
  final int deliveryFee;
  final int taxes;
  final DateTime? updatedAt;

  Cart({
    required this.userId,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 20, // Default delivery fee
    this.taxes = 10, // Default taxes
    this.updatedAt,
  });

  // Helper method to parse items list from dynamic data
  static List<CartItem> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];
    return (itemsData as List<dynamic>)
        .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Helper method to parse integer from dynamic data
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    return value is int ? value : (value as num).toInt();
  }

  // Create from Firestore document
  factory Cart.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return Cart(
      userId: doc.id,
      items: _parseItems(data['items']),
      subtotal: _parseInt(data['subtotal']),
      deliveryFee: _parseInt(data['deliveryFee'], defaultValue: 20),
      taxes: _parseInt(data['taxes'], defaultValue: 10),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map
  factory Cart.fromMap(Map<String, dynamic> map, String userId) {
    return Cart(
      userId: userId,
      items: _parseItems(map['items']),
      subtotal: _parseInt(map['subtotal']),
      deliveryFee: _parseInt(map['deliveryFee'], defaultValue: 20),
      taxes: _parseInt(map['taxes'], defaultValue: 10),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'taxes': taxes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;

  // Get total number of items (sum of quantities)
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // Calculate total price (subtotal + deliveryFee + taxes)
  int get total => subtotal + deliveryFee + taxes;

  // Format total as string
  String get formattedTotal => '$total EGP';

  // Format subtotal as string
  String get formattedSubtotal => '$subtotal EGP';

  // Format delivery fee as string
  String get formattedDeliveryFee => '$deliveryFee EGP';

  // Format taxes as string
  String get formattedTaxes => '$taxes EGP';

  // Create a copy with modified fields
  Cart copyWith({
    String? userId,
    List<CartItem>? items,
    int? subtotal,
    int? deliveryFee,
    int? taxes,
    DateTime? updatedAt,
  }) {
    return Cart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxes: taxes ?? this.taxes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

