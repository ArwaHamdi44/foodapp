import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final int total;
  final String address;
  final String paymentMethod;
  final int deliveryFee;
  final int taxes;
  final OrderStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.deliveryFee,
    required this.taxes,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Helper method to parse items list from dynamic data
  static List<OrderItem> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];
    return (itemsData as List<dynamic>)
        .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Helper method to parse integer from dynamic data
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    return value is int ? value : (value as num).toInt();
  }

  // Create from Firestore document
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: _parseItems(data['items']),
      total: _parseInt(data['total']),
      address: data['address'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      deliveryFee: _parseInt(data['deliveryFee']),
      taxes: _parseInt(data['taxes']),
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map
  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      items: _parseItems(map['items']),
      total: _parseInt(map['total']),
      address: map['address'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      deliveryFee: _parseInt(map['deliveryFee']),
      taxes: _parseInt(map['taxes']),
      status: _parseStatus(map['status']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'address': address,
      'paymentMethod': paymentMethod,
      'deliveryFee': deliveryFee,
      'taxes': taxes,
      'status': status.toString().split('.').last, // Convert enum to string
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Helper method to parse status string to enum
  static OrderStatus _parseStatus(dynamic status) {
    if (status == null) return OrderStatus.pending;

    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'outfordelivery':
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  // Format total price as string
  String get formattedTotal => '$total EGP';

  // Get subtotal (total - deliveryFee - taxes)
  int get subtotal => total - deliveryFee - taxes;

  // Format subtotal as string
  String get formattedSubtotal => '$subtotal EGP';

  // Get status as display string
  String get statusDisplay {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Check if order can be cancelled
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  // Create a copy with modified fields
  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    int? total,
    String? address,
    String? paymentMethod,
    int? deliveryFee,
    int? taxes,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      total: total ?? this.total,
      address: address ?? this.address,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxes: taxes ?? this.taxes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

