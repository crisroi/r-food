import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';

// Cart item class
class CartItem {
  final MenuItem menuItem;
  final int quantity;
  final String? specialInstructions;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

// Cart state
class CartState {
  final List<CartItem> items;
  final String? restaurantId;
  final String? restaurantName;

  CartState({
    this.items = const [],
    this.restaurantId,
    this.restaurantName,
  });

  // Calculate subtotal
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Calculate total items
  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;

  // Check if item is in cart
  bool containsItem(String menuItemId) {
    return items.any((item) => item.menuItem.id == menuItemId);
  }

  // Get quantity of specific item
  int getItemQuantity(String menuItemId) {
    try {
      final item = items.firstWhere(
        (item) => item.menuItem.id == menuItemId,
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  CartState copyWith({
    List<CartItem>? items,
    String? restaurantId,
    String? restaurantName,
  }) {
    return CartState(
      items: items ?? this.items,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }
}

// Cart notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  // Add item to cart
  void addItem({
    required MenuItem menuItem,
    required String restaurantId,
    required String restaurantName,
    int quantity = 1,
    String? specialInstructions,
  }) {
    // If cart has items from different restaurant, clear it first
    if (state.restaurantId != null && state.restaurantId != restaurantId) {
      // You might want to show a dialog here asking user to confirm
      clearCart();
    }

    final existingItemIndex = state.items.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    List<CartItem> updatedItems;

    if (existingItemIndex != -1) {
      // Item already in cart, update quantity
      updatedItems = [...state.items];
      final existingItem = updatedItems[existingItemIndex];
      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
        specialInstructions: specialInstructions ?? existingItem.specialInstructions,
      );
    } else {
      // New item, add to cart
      updatedItems = [
        ...state.items,
        CartItem(
          menuItem: menuItem,
          quantity: quantity,
          specialInstructions: specialInstructions,
        ),
      ];
    }

    state = state.copyWith(
      items: updatedItems,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
  }

  // Remove item from cart
  void removeItem(String menuItemId) {
    final updatedItems = state.items
        .where((item) => item.menuItem.id != menuItemId)
        .toList();

    if (updatedItems.isEmpty) {
      // Cart is now empty, clear restaurant info
      state = CartState();
    } else {
      state = state.copyWith(items: updatedItems);
    }
  }

  // Update item quantity
  void updateQuantity(String menuItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(menuItemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.menuItem.id == menuItemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  // Increment item quantity
  void incrementItem(String menuItemId) {
    final item = state.items.firstWhere(
      (item) => item.menuItem.id == menuItemId,
    );
    updateQuantity(menuItemId, item.quantity + 1);
  }

  // Decrement item quantity
  void decrementItem(String menuItemId) {
    final item = state.items.firstWhere(
      (item) => item.menuItem.id == menuItemId,
    );
    updateQuantity(menuItemId, item.quantity - 1);
  }

  // Update special instructions
  void updateSpecialInstructions(String menuItemId, String instructions) {
    final updatedItems = state.items.map((item) {
      if (item.menuItem.id == menuItemId) {
        return item.copyWith(specialInstructions: instructions);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  // Clear cart
  void clearCart() {
    state = CartState();
  }

  // Check if can switch restaurant
  bool canSwitchRestaurant(String newRestaurantId) {
    return state.restaurantId == null || 
           state.restaurantId == newRestaurantId || 
           state.items.isEmpty;
  }
}

// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// Computed providers for cart values
final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.subtotal;
});

final cartTotalItemsProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.totalItems;
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.isEmpty;
});

// Provider to check if specific item is in cart
final isInCartProvider = Provider.family<bool, String>((ref, menuItemId) {
  final cart = ref.watch(cartProvider);
  return cart.containsItem(menuItemId);
});

// Provider to get quantity of specific item
final itemQuantityProvider = Provider.family<int, String>((ref, menuItemId) {
  final cart = ref.watch(cartProvider);
  return cart.getItemQuantity(menuItemId);
});
