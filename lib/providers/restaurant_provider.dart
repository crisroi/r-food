// providers/restaurant_provider.dart (FIXED)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/menu_item_model.dart';
import 'firestore_provider.dart';
import 'auth_provider.dart';

// ==================== RESTAURANT PROVIDERS ====================

// Get all restaurants (users with role = "restaurant")
final restaurantsProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('users')
      .where('role', isEqualTo: 'restaurant')
      .where('isOpen', isEqualTo: true)  // Only show open restaurants
      .snapshots()
      .map((snapshot) =>
      snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
});

// Get a single restaurant by ID
final restaurantProvider = StreamProvider.family<UserModel?, String>((ref, restaurantId) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('users')
      .doc(restaurantId)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  });
});

// Get current user's restaurant info (if they are a restaurant owner)
final myRestaurantProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();

      return firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
        if (doc.exists && doc.data()?['role'] == 'restaurant') {
          return UserModel.fromFirestore(doc);
        }
        return null;
      });
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// ==================== MENU ITEM PROVIDERS ====================

// Get all menu items for a restaurant
final menuItemsProvider = StreamProvider.family<List<MenuItem>, String>((ref, restaurantId) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .map((snapshot) =>
      snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList());
});

// Get all menu items for current restaurant owner
final myMenuItemsProvider = StreamProvider<List<MenuItem>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();

      return firestore
          .collection('menuItems')
          .where('restaurantId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList());
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// ==================== RESTAURANT SERVICES ====================

class RestaurantService {
  final FirebaseFirestore _firestore;

  RestaurantService(this._firestore);

  // Toggle restaurant open/close status
  Future<void> toggleRestaurantStatus(String restaurantId, bool isOpen) async {
    await _firestore
        .collection('users')
        .doc(restaurantId)
        .update({
      'isOpen': isOpen,
    });
  }

  // Update restaurant info
  Future<void> updateRestaurantInfo({
    required String restaurantId,
    String? restaurantName,
    String? location,
    Map<String, String>? operatingHours,
    String? restaurantLogoUrl,
  }) async {
    final updates = <String, dynamic>{};

    if (restaurantName != null) {
      updates['restaurantName'] = restaurantName;
    }
    if (location != null) {
      updates['location'] = location;
    }
    if (operatingHours != null) {
      updates['operatingHours'] = operatingHours;
    }
    // This was the missing part!
    if (restaurantLogoUrl != null) {
      updates['restaurantLogoUrl'] = restaurantLogoUrl;
    }

    if (updates.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(restaurantId)
          .update(updates);
    }
  }
}

final restaurantServiceProvider = Provider<RestaurantService>((ref) {
  return RestaurantService(ref.watch(firestoreProvider));
});

// ==================== MENU ITEM SERVICES ====================

class MenuItemService {
  final FirebaseFirestore _firestore;

  MenuItemService(this._firestore);

  // Create a new menu item
  Future<String> createMenuItem(MenuItem item) async {
    final docRef = await _firestore
        .collection('menuItems')
        .add(item.toFirestore());
    return docRef.id;
  }

  // Update menu item
  Future<void> updateMenuItem(MenuItem item) async {
    await _firestore
        .collection('menuItems')
        .doc(item.id)
        .update(item.toFirestore());
  }

  // Toggle menu item availability
  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    await _firestore
        .collection('menuItems')
        .doc(itemId)
        .update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update quantity
  Future<void> updateQuantity(String itemId, int quantity) async {
    await _firestore
        .collection('menuItems')
        .doc(itemId)
        .update({
      'quantityAvailable': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete menu item
  Future<void> deleteMenuItem(String itemId) async {
    await _firestore
        .collection('menuItems')
        .doc(itemId)
        .delete();
  }
}

final menuItemServiceProvider = Provider<MenuItemService>((ref) {
  return MenuItemService(ref.watch(firestoreProvider));
});
