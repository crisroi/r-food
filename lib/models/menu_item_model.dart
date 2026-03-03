import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String subCategory;
  final String imageUrl; // Required - Cloudinary URL
  final bool isAvailable;
  final int? quantityAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    required this.subCategory,
    required this.imageUrl,
    this.isAvailable = true,
    this.quantityAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get category display text
  String get categoryDisplay {
    return '$category - $subCategory';
  }

  // Convert from Firestore document
  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? 'Food',
      subCategory: data['subCategory'] ?? 'Rice',
      imageUrl: data['imageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      quantityAvailable: data['quantityAvailable'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'category': category,
      'subCategory': subCategory,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      if (quantityAvailable != null) 'quantityAvailable': quantityAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method
  MenuItem copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? subCategory,
    String? imageUrl,
    bool? isAvailable,
    int? quantityAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Category definitions
class MenuCategory {
  static const String food = 'Food';
  static const String drink = 'Drink';
  static const String dessert = 'Dessert';

  static const List<String> mainCategories = [food, drink, dessert];

  static const Map<String, List<String>> subCategories = {
    food: ['Rice', 'Swallow', 'Soup', 'Meat', 'Egg', 'Pack', 'Others'],
    drink: ['Water', 'Soft Drinks', 'Others'],
    dessert: ['Ice Cream', 'Others'],
  };

  static List<String> getSubCategories(String mainCategory) {
    return subCategories[mainCategory] ?? [];
  }
}