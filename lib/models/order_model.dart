import 'package:cloud_firestore/cloud_firestore.dart';

import 'individual_order_model.dart';

// OrderItem is now imported from individual_order_model.dart

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantLocation;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String orderType; // "delivery" or "pickup"
  final String? deliveryLocation;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? scheduledFor;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedReadyTime;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final int? restaurantRating;
  final String? restaurantReview;
  final int? deliveryPartnerRating;
  final String? deliveryPartnerReview;
  final List<IndividualOrder> individualOrders;
  final int orderCount;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantLocation,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.orderType,
    this.deliveryLocation,
    this.paymentMethod = 'wallet',
    this.paymentStatus = 'pending',
    this.scheduledFor,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.estimatedReadyTime,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.pickedUpAt,
    this.deliveredAt,
    this.restaurantRating,
    this.restaurantReview,
    this.deliveryPartnerRating,
    this.deliveryPartnerReview,
    required this.individualOrders,
    required this.orderCount,
  });

  // Convert from Firestore document
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantLocation: data['restaurantLocation'],
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      orderType: data['orderType'] ?? 'pickup',
      deliveryLocation: data['deliveryLocation'],
      paymentMethod: data['paymentMethod'] ?? 'wallet',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      scheduledFor: (data['scheduledFor'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedReadyTime: (data['estimatedReadyTime'] as Timestamp?)?.toDate(),
      deliveryPartnerId: data['deliveryPartnerId'],
      deliveryPartnerName: data['deliveryPartnerName'],
      pickedUpAt: (data['pickedUpAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      restaurantRating: data['restaurantRating'],
      restaurantReview: data['restaurantReview'],
      deliveryPartnerRating: data['deliveryPartnerRating'],
      deliveryPartnerReview: data['deliveryPartnerReview'],
      individualOrders: (data['individualOrders'] as List<dynamic>?)
          ?.map((order) => IndividualOrder.fromMap(order as Map<String, dynamic>))
          .toList() ??
          [],
      orderCount: data['orderCount'] ?? 1,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      if (restaurantLocation != null) 'restaurantLocation': restaurantLocation,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'orderType': orderType,
      if (deliveryLocation != null) 'deliveryLocation': deliveryLocation,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      if (scheduledFor != null) 'scheduledFor': Timestamp.fromDate(scheduledFor!),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (estimatedReadyTime != null)
        'estimatedReadyTime': Timestamp.fromDate(estimatedReadyTime!),
      if (deliveryPartnerId != null) 'deliveryPartnerId': deliveryPartnerId,
      if (deliveryPartnerName != null) 'deliveryPartnerName': deliveryPartnerName,
      if (pickedUpAt != null) 'pickedUpAt': Timestamp.fromDate(pickedUpAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
      if (restaurantRating != null) 'restaurantRating': restaurantRating,
      if (restaurantReview != null) 'restaurantReview': restaurantReview,
      if (deliveryPartnerRating != null)
        'deliveryPartnerRating': deliveryPartnerRating,
      if (deliveryPartnerReview != null)
        'deliveryPartnerReview': deliveryPartnerReview,
      'individualOrders': individualOrders.map((order) => order.toMap()).toList(),
      'orderCount': orderCount,
    };
  }

  // Copy with method
  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? restaurantId,
    String? restaurantName,
    String? restaurantLocation,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    String? orderType,
    String? deliveryLocation,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? scheduledFor,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? estimatedReadyTime,
    String? deliveryPartnerId,
    String? deliveryPartnerName,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    int? restaurantRating,
    String? restaurantReview,
    int? deliveryPartnerRating,
    String? deliveryPartnerReview,
    List<IndividualOrder>? individualOrders,
    int? orderCount,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      orderType: orderType ?? this.orderType,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedReadyTime: estimatedReadyTime ?? this.estimatedReadyTime,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      restaurantRating: restaurantRating ?? this.restaurantRating,
      restaurantReview: restaurantReview ?? this.restaurantReview,
      deliveryPartnerRating: deliveryPartnerRating ?? this.deliveryPartnerRating,
      deliveryPartnerReview: deliveryPartnerReview ?? this.deliveryPartnerReview,
      individualOrders: individualOrders ?? this.individualOrders,
      orderCount: orderCount ?? this.orderCount,
    );
  }

  // Helper: Check if order can be cancelled
  bool get canBeCancelled {
    return status == 'pending' || status == 'confirmed';
  }

  // Helper: Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'ready':
        return 'Ready';
      case 'picked_up':
        return 'Picked Up';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Helper: Total number of items
  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Helper: Check if order is delivery
  bool get isDelivery => orderType == 'delivery';

  // Helper: Check if order is pickup
  bool get isPickup => orderType == 'pickup';

  // Helper: Check if delivery partner can be rated
  bool get canRateDeliveryPartner {
    return isDelivery &&
        deliveryPartnerId != null &&
        (status == 'delivered' || status == 'completed') &&
        deliveryPartnerRating == null;
  }

  // Helper: Check if restaurant can be rated
  bool get canRateRestaurant {
    return (status == 'delivered' || status == 'completed') &&
        restaurantRating == null;
  }
}

// Order status definitions
class OrderStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String ready = 'ready';
  static const String pickedUp = 'picked_up';
  static const String delivered = 'delivered';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> allStatuses = [
    pending,
    confirmed,
    ready,
    pickedUp,
    delivered,
    completed,
    cancelled,
  ];
}

// Delivery locations
class DeliveryLocations {
  static const List<String> hostels = [
    'Main Hostel (Boys)',
    'Main Hostel (Girls)',
    'Extension (Boys)',
    'Extension (Girls)',
    'Engineering Hostel (Boys)',
    'Engineering Hostel (Girls)',
  ];

  static const List<String> lectureAreas = [
    'Lecture Area (NLT)',
    'Lecture Area (MLT)',
    'Lecture Area (LR 1)',
    'Lecture Area (LR 2)',
    'Lecture Area (LR 3)',
    'Lecture Area (LR 4)',
    'Lecture Area (LR 5)',
    'Lecture Area (LR 6)',
    'Lecture Area (LR 7)',
    'Lecture Area (LR 8)',
    'Lecture Area (LR 9)',
    'Lecture Area (LR 10)',
    'Lecture Area (LR 11)',
    'Lecture Area (LR 12)',
    'Lecture Area (LR 13)',
    'Lecture Area (LR 14)',
    'Lecture Area (LR 15)',
    'Lecture Area (LR 16)',
    'Lecture Area (LR 17)',
    'Lecture Area (LR 18)',
    'Lecture Area (LR 19)',
    'Lecture Area (LR 20)',
    'Lecture Area (LR 21)',
    'Lecture Area (LR 22)',
    'Lecture Area (LR 23)',
    'Lecture Area (LR 24)',
  ];

  static List<String> get allLocations => [...hostels, ...lectureAreas];
}