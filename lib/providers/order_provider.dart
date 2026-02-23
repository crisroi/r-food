import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import 'firestore_provider.dart';
import 'auth_provider.dart';

// ==================== ORDER PROVIDERS ====================

// Get all orders for current customer
final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      return firestore
          .collection('orders')
          .where('customerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Get active orders for current customer (not delivered or cancelled)
final myActiveOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      return firestore
          .collection('orders')
          .where('customerId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'confirmed', 'preparing', 'ready', 'picked_up'])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Get orders for a restaurant
final restaurantOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      return firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Get pending orders for restaurant (needs confirmation)
final restaurantPendingOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      return firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Get active orders for restaurant (confirmed, preparing, ready)
final restaurantActiveOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      return firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: user.uid)
          .where('status', whereIn: ['confirmed', 'preparing', 'ready'])
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Get orders for delivery partner
final deliveryPartnerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      return firestore
          .collection('orders')
          .where('deliveryPartnerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Get available orders for delivery (ready for pickup, no delivery partner assigned)
final availableDeliveryOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  
  return firestore
      .collection('orders')
      .where('status', isEqualTo: 'ready')
      .where('deliveryPartnerId', isNull: true)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
});

// Get active deliveries for delivery partner
final activeDeliveriesProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      return firestore
          .collection('orders')
          .where('deliveryPartnerId', isEqualTo: user.uid)
          .where('status', whereIn: ['picked_up'])
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Get a single order by ID
final orderProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final firestore = ref.watch(firestoreProvider);
  
  return firestore
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) {
        if (doc.exists) {
          return OrderModel.fromFirestore(doc);
        }
        return null;
      });
});

// ==================== ORDER SERVICES ====================

class OrderService {
  final FirebaseFirestore _firestore;

  OrderService(this._firestore);

  // Create a new order
  Future<String> createOrder(OrderModel order) async {
    final docRef = await _firestore
        .collection('orders')
        .add(order.toFirestore());
    return docRef.id;
  }

  // Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    required String updatedBy,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final orderDoc = await orderRef.get();
    
    if (!orderDoc.exists) {
      throw Exception('Order not found');
    }

    await orderRef.update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Assign delivery partner to order
  Future<void> assignDeliveryPartner({
    required String orderId,
    required String deliveryPartnerId,
    required String deliveryPartnerName,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'deliveryPartnerId': deliveryPartnerId,
      'deliveryPartnerName': deliveryPartnerName,
      'status': 'picked_up',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String userId) async {
    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'cancelled',
      updatedBy: userId,
    );
  }

  // Mark order as delivered
  Future<void> markAsDelivered(String orderId, String userId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'delivered',
      'actualDeliveryTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await updateOrderStatus(
      orderId: orderId,
      newStatus: 'delivered',
      updatedBy: userId,
    );
  }

  // Add rating and review
  Future<void> addRatingAndReview({
    required String orderId,
    required int rating,
    String? review,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'rating': rating,
      if (review != null) 'review': review,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update estimated delivery time
  Future<void> updateEstimatedDeliveryTime({
    required String orderId,
    required DateTime estimatedTime,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'estimatedDeliveryTime': Timestamp.fromDate(estimatedTime),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get order statistics for restaurant
  Future<Map<String, dynamic>> getRestaurantOrderStats(String restaurantId) async {
    final orders = await _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    int totalOrders = orders.docs.length;
    int completedOrders = orders.docs
        .where((doc) => doc.data()['status'] == 'delivered')
        .length;
    int cancelledOrders = orders.docs
        .where((doc) => doc.data()['status'] == 'cancelled')
        .length;
    
    double totalRevenue = 0;
    for (var doc in orders.docs) {
      if (doc.data()['status'] == 'delivered') {
        final pricing = doc.data()['pricing'] as Map<String, dynamic>;
        totalRevenue += (pricing['total'] ?? 0.0) as double;
      }
    }

    return {
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'totalRevenue': totalRevenue,
      'completionRate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
    };
  }

  // Get order statistics for delivery partner
  Future<Map<String, dynamic>> getDeliveryPartnerStats(String deliveryPartnerId) async {
    final orders = await _firestore
        .collection('orders')
        .where('deliveryPartnerId', isEqualTo: deliveryPartnerId)
        .get();

    int totalDeliveries = orders.docs.length;
    int completedDeliveries = orders.docs
        .where((doc) => doc.data()['status'] == 'delivered')
        .length;
    
    double totalEarnings = 0;
    for (var doc in orders.docs) {
      if (doc.data()['status'] == 'delivered') {
        final pricing = doc.data()['pricing'] as Map<String, dynamic>;
        totalEarnings += (pricing['deliveryFee'] ?? 0.0) as double;
      }
    }

    return {
      'totalDeliveries': totalDeliveries,
      'completedDeliveries': completedDeliveries,
      'totalEarnings': totalEarnings,
      'completionRate': totalDeliveries > 0 ? (completedDeliveries / totalDeliveries) * 100 : 0,
    };
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(firestoreProvider));
});
