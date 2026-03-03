import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single order within a multi-order transaction
/// Example: Customer orders 3 meals - each meal is an IndividualOrder
class IndividualOrder {
  final List<OrderItem> foodItems;
  final List<OrderItem> drinkItems;
  final List<OrderItem> dessertItems;
  final OrderItem? packItem; // Only one pack per individual order
  final String? specialInstructions;

  IndividualOrder({
    this.foodItems = const [],
    this.drinkItems = const [],
    this.dessertItems = const [],
    this.packItem,
    this.specialInstructions,
  });

  /// Calculate subtotal for this individual order (including pack)
  double get subtotal {
    double total = 0;
    total += foodItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    total += drinkItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    total += dessertItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    if (packItem != null) {
      total += packItem!.totalPrice;
    }
    return total;
  }

  /// Calculate subtotal excluding pack (for minimum order validation)
  double get subtotalWithoutPack {
    double total = 0;
    total += foodItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    total += drinkItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    total += dessertItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    // Pack explicitly excluded
    return total;
  }

  /// Get all items (food + drink + dessert + pack)
  List<OrderItem> get allItems {
    final items = <OrderItem>[
      ...foodItems,
      ...drinkItems,
      ...dessertItems,
    ];
    if (packItem != null) {
      items.add(packItem!);
    }
    return items;
  }

  /// Total number of items in this order
  int get totalItems {
    return allItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Check if order has any items
  bool get isEmpty {
    return foodItems.isEmpty &&
        drinkItems.isEmpty &&
        dessertItems.isEmpty &&
        packItem == null;
  }

  bool get isNotEmpty => !isEmpty;

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'foodItems': foodItems.map((item) => item.toMap()).toList(),
      'drinkItems': drinkItems.map((item) => item.toMap()).toList(),
      'dessertItems': dessertItems.map((item) => item.toMap()).toList(),
      if (packItem != null) 'packItem': packItem!.toMap(),
      if (specialInstructions != null)
        'specialInstructions': specialInstructions,
    };
  }

  /// Create from map
  factory IndividualOrder.fromMap(Map<String, dynamic> map) {
    return IndividualOrder(
      foodItems: (map['foodItems'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      drinkItems: (map['drinkItems'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      dessertItems: (map['dessertItems'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      packItem: map['packItem'] != null
          ? OrderItem.fromMap(map['packItem'] as Map<String, dynamic>)
          : null,
      specialInstructions: map['specialInstructions'],
    );
  }

  /// Copy with method
  IndividualOrder copyWith({
    List<OrderItem>? foodItems,
    List<OrderItem>? drinkItems,
    List<OrderItem>? dessertItems,
    OrderItem? packItem,
    bool clearPack = false,
    String? specialInstructions,
  }) {
    return IndividualOrder(
      foodItems: foodItems ?? this.foodItems,
      drinkItems: drinkItems ?? this.drinkItems,
      dessertItems: dessertItems ?? this.dessertItems,
      packItem: clearPack ? null : (packItem ?? this.packItem),
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

/// Single item in an order
class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? notes;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
    };
  }

  double get totalPrice => price * quantity;

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    double? price,
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}