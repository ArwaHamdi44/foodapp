import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class Cart {
  final String userId; 
  final List<CartItem> items;
  final int subtotal;
  final int deliveryFee;
  final int taxes;
  final DateTime? updatedAt;

  Cart({
    required this.userId,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 20, 
    this.taxes = 10, 
    this.updatedAt,
  });

 
  static List<CartItem> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];
    return (itemsData as List<dynamic>)
        .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    return value is int ? value : (value as num).toInt();
  }


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

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'taxes': taxes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isEmpty => items.isEmpty;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

 
  int get total => subtotal + deliveryFee + taxes;

  
  String get formattedTotal => '$total EGP';

  String get formattedSubtotal => '$subtotal EGP';

  String get formattedDeliveryFee => '$deliveryFee EGP';

 
  String get formattedTaxes => '$taxes EGP';

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

