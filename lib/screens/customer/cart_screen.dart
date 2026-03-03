import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:r_foods/providers/cart_provider.dart';
import 'package:r_foods/providers/auth_provider.dart';
import 'package:r_foods/models/order_model.dart';
import 'package:r_foods/models/individual_order_model.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String _orderType = 'pickup'; // 'pickup' or 'delivery'
  String? _selectedLocation;
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Cart', style: TextStyle(color: textColor))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: subtextColor),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, color: subtextColor),
              ),
            ],
          ),
        ),
      );
    }

    final deliveryFee = _orderType == 'delivery' ? 200.0 : 0.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: textColor),
            onPressed: () => _showClearCartDialog(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Cart items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final cartItem = cart.items[index];
                    return _CartItemCard(cartItem: cartItem);
                  },
                ),
              ),

              // Order type selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: borderColor),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Pickup', style: TextStyle(color: textColor)),
                            subtitle: Text('Free', style: TextStyle(color: subtextColor)),
                            value: 'pickup',
                            groupValue: _orderType,
                            onChanged: (value) =>
                                setState(() => _orderType = value!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Delivery', style: TextStyle(color: textColor)),
                            subtitle: Text('₦200', style: TextStyle(color: subtextColor)),
                            value: 'delivery',
                            groupValue: _orderType,
                            onChanged: (value) =>
                                setState(() => _orderType = value!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),

                    // Delivery location dropdown
                    if (_orderType == 'delivery') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: cardColor,
                        value: _selectedLocation,
                        decoration: InputDecoration(
                          labelText: 'Delivery Location',
                          labelStyle: TextStyle(color: subtextColor),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: TextStyle(color: textColor),
                        items: DeliveryLocations.allLocations
                            .map((loc) =>
                            DropdownMenuItem(value: loc, child: Text(loc, style: TextStyle(color: textColor))))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedLocation = value),
                      ),
                    ],
                  ],
                ),
              ),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', subtotal, textColor),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Delivery Fee', deliveryFee, textColor),
                    Divider(height: 24, color: isDark ? Colors.grey[700] : null),
                    _buildSummaryRow('Total', total, textColor, isBold: true),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color textColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
        Text(
          '₦${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.green : textColor,
          ),
        ),
      ],
    );
  }

  void _showClearCartDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Clear Cart', style: TextStyle(color: textColor)),
        content: Text('Are you sure you want to remove all items?', style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_orderType == 'delivery' && _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      if (userData == null) throw Exception('User data not found');

      final cart = ref.read(cartProvider);
      final subtotal = ref.read(cartSubtotalProvider);
      final deliveryFee = _orderType == 'delivery' ? 200.0 : 0.0;
      final total = subtotal + deliveryFee;

      // Create order items
      final orderItems = cart.items
          .map((item) => OrderItem(
        menuItemId: item.menuItem.id,
        name: item.menuItem.name,
        price: item.menuItem.price,
        quantity: item.quantity,
        notes: item.specialInstructions,
      ))
          .toList();

      // Create single individual order (for backward compatibility with old cart system)
      final individualOrder = IndividualOrder(
        foodItems: orderItems
            .where((item) =>
        cart.items
            .firstWhere((ci) => ci.menuItem.id == item.menuItemId)
            .menuItem
            .category ==
            'Food')
            .toList(),
        drinkItems: orderItems
            .where((item) =>
        cart.items
            .firstWhere((ci) => ci.menuItem.id == item.menuItemId)
            .menuItem
            .category ==
            'Drink')
            .toList(),
        dessertItems: orderItems
            .where((item) =>
        cart.items
            .firstWhere((ci) => ci.menuItem.id == item.menuItemId)
            .menuItem
            .category ==
            'Dessert')
            .toList(),
      );

      // Create order
      final order = OrderModel(
        id: '', // Will be set by Firestore
        customerId: user.uid,
        customerName: '${userData['firstname']} ${userData['lastname']}',
        customerPhone: userData['phoneNumber'] ?? '',
        restaurantId: cart.restaurantId!,
        restaurantName: cart.restaurantName!,
        items: orderItems,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        orderType: _orderType,
        deliveryLocation: _selectedLocation,
        paymentMethod: 'wallet',
        paymentStatus: 'pending',
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        individualOrders: [individualOrder],
        orderCount: 1,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .add(order.toFirestore());

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;

      // Show success dialog
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: cardColor,
          title: Text('Order Placed! 🎉', style: TextStyle(color: textColor)),
          content: Text(
            'Your order has been placed successfully.\n\n'
                'The restaurant will confirm your order soon.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }
}

class _CartItemCard extends ConsumerWidget {
  final CartItem cartItem;

  const _CartItemCard({required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                cartItem.menuItem.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.restaurant, color: subtextColor),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.menuItem.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${cartItem.menuItem.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  if (cartItem.specialInstructions != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      cartItem.specialInstructions!,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Quantity controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 18, color: textColor),
                    onPressed: () => ref
                        .read(cartProvider.notifier)
                        .incrementItem(cartItem.menuItem.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  Text(
                    cartItem.quantity.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove, size: 18, color: textColor),
                    onPressed: () => ref
                        .read(cartProvider.notifier)
                        .decrementItem(cartItem.menuItem.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}