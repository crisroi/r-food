import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:r_foods/models/individual_order_model.dart';
import 'package:r_foods/models/order_model.dart';
import 'package:r_foods/providers/auth_provider.dart';

class MultiOrderCheckoutScreen extends ConsumerStatefulWidget {
  final List<IndividualOrder> orders;
  final String restaurantId;
  final String restaurantName;
  final Function(int) onDuplicateOrder;
  final Function(int) onEditOrder;
  final Function(int) onDeleteOrder;

  const MultiOrderCheckoutScreen({
    super.key,
    required this.orders,
    required this.restaurantId,
    required this.restaurantName,
    required this.onDuplicateOrder,
    required this.onEditOrder,
    required this.onDeleteOrder,
  });

  @override
  ConsumerState<MultiOrderCheckoutScreen> createState() =>
      _MultiOrderCheckoutScreenState();
}

class _MultiOrderCheckoutScreenState
    extends ConsumerState<MultiOrderCheckoutScreen> {
  String _orderType = 'pickup';
  String? _selectedLocation;
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    // Dark Mode Theme Variables
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    // Calculate totals
    final subtotalWithoutPack = _calculateSubtotalWithoutPack();
    final subtotalWithPack = _calculateSubtotalWithPack();
    final deliveryFee = _orderType == 'delivery' ? 200.0 : 0.0;
    final grandTotal = subtotalWithPack + deliveryFee;
    final meetsMinimum = subtotalWithoutPack >= 500;

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Order', style: TextStyle(color: textColor)),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: textColor),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: Column(
        children: [
          // Orders list
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        '${widget.orders.length} Order${widget.orders.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.restaurantName,
                        style: TextStyle(
                          fontSize: 16,
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Minimum order warning
                      if (!meetsMinimum)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Minimum Order Not Met',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Minimum: ₦500 (excluding pack)\nCurrent: ₦${subtotalWithoutPack.toStringAsFixed(0)}\nNeed: ₦${(500 - subtotalWithoutPack).toStringAsFixed(0)} more',
                                      style: const TextStyle(fontSize: 13, color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Individual orders
                      ...List.generate(widget.orders.length, (index) {
                        return _buildOrderCard(index, widget.orders[index], cardColor, textColor, subtextColor!, isDark);
                      }),

                      const SizedBox(height: 24),

                      // Order type selection
                      Text(
                        'Order Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: Text('Pickup', style: TextStyle(color: textColor)),
                              subtitle: Text('Free', style: TextStyle(color: subtextColor)),
                              value: 'pickup',
                              groupValue: _orderType,
                              onChanged: (value) =>
                                  setState(() => _orderType = value!),
                            ),
                            Divider(height: 1, color: isDark ? Colors.grey[700] : null),
                            RadioListTile<String>(
                              title: Text('Delivery', style: TextStyle(color: textColor)),
                              subtitle: Text('₦200', style: TextStyle(color: subtextColor)),
                              value: 'delivery',
                              groupValue: _orderType,
                              onChanged: (value) =>
                                  setState(() => _orderType = value!),
                            ),
                          ],
                        ),
                      ),

                      // Delivery location
                      if (_orderType == 'delivery') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          dropdownColor: cardColor,
                          style: TextStyle(color: textColor),
                          value: _selectedLocation,
                          decoration: InputDecoration(
                            labelText: 'Delivery Location',
                            labelStyle: TextStyle(color: subtextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                          items: DeliveryLocations.allLocations
                              .map((loc) => DropdownMenuItem(
                            value: loc,
                            child: Text(loc, style: TextStyle(color: textColor)),
                          ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedLocation = value),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Summary and checkout button
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
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', subtotalWithPack, textColor),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Delivery Fee', deliveryFee, textColor),
                      Divider(height: 24, color: isDark ? Colors.grey[700] : null),
                      _buildSummaryRow('Total', grandTotal, textColor, isBold: true),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: meetsMinimum && !_isPlacingOrder
                              ? _placeOrder
                              : null,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(int index, IndividualOrder order, Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order ${index + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                // Action buttons
                IconButton(
                  icon: Icon(Icons.copy, size: 20, color: subtextColor),
                  onPressed: () => widget.onDuplicateOrder(index),
                  tooltip: 'Duplicate',
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: subtextColor),
                  onPressed: () => widget.onEditOrder(index),
                  tooltip: 'Edit',
                ),
                if (widget.orders.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _confirmDeleteOrder(index),
                    tooltip: 'Delete',
                    color: Colors.red,
                  ),
              ],
            ),
            Divider(height: 20, color: isDark ? Colors.grey[700] : null),

            // Food items
            if (order.foodItems.isNotEmpty) ...[
              Text(
                'Food',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 8),
              ...order.foodItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.quantity}x ${item.name}', style: TextStyle(color: textColor)),
                    ),
                    Text(
                      '₦${item.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],

            // Drink items
            if (order.drinkItems.isNotEmpty) ...[
              Text(
                'Drinks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 8),
              ...order.drinkItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.quantity}x ${item.name}', style: TextStyle(color: textColor)),
                    ),
                    Text(
                      '₦${item.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],

            // Dessert items
            if (order.dessertItems.isNotEmpty) ...[
              Text(
                'Desserts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 8),
              ...order.dessertItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.quantity}x ${item.name}', style: TextStyle(color: textColor)),
                    ),
                    Text(
                      '₦${item.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],

            // Pack item
            if (order.packItem != null) ...[
              Text(
                'Pack',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                        '${order.packItem!.quantity}x ${order.packItem!.name}', style: TextStyle(color: textColor)),
                  ),
                  Text(
                    '₦${order.packItem!.totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Order total
            Divider(height: 20, color: isDark ? Colors.grey[700] : null),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Total',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  '₦${order.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
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

  double _calculateSubtotalWithoutPack() {
    double total = 0;
    for (var order in widget.orders) {
      total += order.subtotalWithoutPack;
    }
    return total;
  }

  double _calculateSubtotalWithPack() {
    double total = 0;
    for (var order in widget.orders) {
      total += order.subtotal;
    }
    return total;
  }

  void _confirmDeleteOrder(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Delete Order', style: TextStyle(color: textColor)),
        content: Text('Are you sure you want to delete Order ${index + 1}?', style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteOrder(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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

      final subtotalWithPack = _calculateSubtotalWithPack();
      final deliveryFee = _orderType == 'delivery' ? 200.0 : 0.0;
      final total = subtotalWithPack + deliveryFee;

      // Convert individual orders to flat list for legacy compatibility
      final allItems = <OrderItem>[];
      for (var order in widget.orders) {
        allItems.addAll(order.allItems);
      }

      // Create order
      final order = OrderModel(
        id: '',
        customerId: user.uid,
        customerName: '${userData['firstname']} ${userData['lastname']}',
        customerPhone: userData['phoneNumber'] ?? '',
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        items: allItems,
        subtotal: subtotalWithPack,
        deliveryFee: deliveryFee,
        total: total,
        orderType: _orderType,
        deliveryLocation: _selectedLocation,
        paymentMethod: 'wallet',
        paymentStatus: 'pending',
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        individualOrders: widget.orders,
        orderCount: widget.orders.length,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .add(order.toFirestore());

      if (!mounted) return;

      // Show success and navigate back
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
            'Your ${widget.orders.length} order${widget.orders.length > 1 ? 's have' : ' has'} been placed successfully.\n\n'
                'The restaurant will confirm shortly.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close checkout
                Navigator.pop(context); // Close multi-order flow
                Navigator.pop(context); // Back to dashboard
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

// Delivery locations
class DeliveryLocations {
  static const List<String> allLocations = [
    'Main Gate',
    'Block A',
    'Block B',
    'Block C',
    'Block D',
    'Block E',
    'Block F',
    'Block G',
    'Engineering Block',
    'Medical Block',
    'Science Block',
    'Arts Block',
    'Library',
    'Sports Complex',
    'Male Hostel 1',
    'Male Hostel 2',
    'Female Hostel 1',
    'Female Hostel 2',
    'Postgraduate Hostel',
    'Staff Quarters',
    'Admin Block',
    'Student Union',
    'Cafeteria',
    'Health Center',
    'Chapel',
    'Mosque',
    'Car Park A',
    'Car Park B',
    'Stadium',
    'Lecture Theatre 1',
    'Lecture Theatre 2',
    'Lab Complex',
    'Workshop',
  ];
}
