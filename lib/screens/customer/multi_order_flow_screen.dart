import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:r_foods/providers/restaurant_provider.dart';
import 'package:r_foods/models/menu_item_model.dart';
import 'package:r_foods/models/individual_order_model.dart';
import 'package:r_foods/screens/customer/multi_order_checkout_screen.dart';

class MultiOrderFlowScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MultiOrderFlowScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  ConsumerState<MultiOrderFlowScreen> createState() =>
      _MultiOrderFlowScreenState();
}

class _MultiOrderFlowScreenState extends ConsumerState<MultiOrderFlowScreen> {
  // Order flow state
  int totalOrders = 1;
  int currentOrderIndex = 0;
  String currentCategory = 'Food';
  List<IndividualOrder> completedOrders = [];

  // Current order being built
  List<OrderItem> currentFoodItems = [];
  List<OrderItem> currentDrinkItems = [];
  List<OrderItem> currentDessertItems = [];
  OrderItem? currentPackItem;

  // Flow stages
  OrderStage currentStage = OrderStage.selectCount;

  // Available categories (filtered by what restaurant has)
  List<String> availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableCategories();
  }

  Future<void> _loadAvailableCategories() async {
    final menuItems = await ref.read(menuItemsProvider(widget.restaurantId).future);
    final categories = <String>{};
    for (var item in menuItems) {
      categories.add(item.category);
    }
    setState(() {
      availableCategories = categories.toList()..sort();
      if (availableCategories.isNotEmpty) {
        currentCategory = availableCategories.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName, style: TextStyle(color: textColor)),
        actions: [
          if (currentStage == OrderStage.ordering)
            IconButton(
              icon: Icon(Icons.info_outline, color: textColor),
              onPressed: _showOrderingHelp,
            ),
        ],
      ),
      body: SafeArea(
        child: _buildCurrentStage(),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (currentStage) {
      case OrderStage.selectCount:
        return _buildOrderCountSelection();
      case OrderStage.ordering:
        return _buildOrderingInterface();
      case OrderStage.summary:
        return _buildOrderSummary();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAGE 1: SELECT NUMBER OF ORDERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOrderCountSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'How many orders do you want to make?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Each order can have food, drinks, and dessert',
                style: TextStyle(color: subtextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, size: 40),
                    onPressed:
                    totalOrders > 1 ? () => setState(() => totalOrders--) : null,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      totalOrders.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 40),
                    onPressed: () => setState(() => totalOrders++),
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentStage = OrderStage.ordering;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start Ordering',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAGE 2: ORDERING INTERFACE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOrderingInterface() {
    return Column(
      children: [
        // Progress indicator
        _buildProgressHeader(),

        // Category tabs
        _buildCategoryTabs(),

        // Menu items for current category
        Expanded(
          child: _buildMenuItemsList(),
        ),

        // Current order summary bar
        _buildCurrentOrderBar(),

        // Navigation buttons
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProgressHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ${currentOrderIndex + 1} of $totalOrders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'Category: $currentCategory',
                style: TextStyle(color: subtextColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (currentOrderIndex + 1) / totalOrders,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      height: 60,
      color: cardColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: availableCategories.length,
        itemBuilder: (context, index) {
          final category = availableCategories[index];
          final isSelected = currentCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => currentCategory = category);
                }
              },
              selectedColor: Colors.orange,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemsList() {
    final menuItemsAsync = ref.watch(menuItemsProvider(widget.restaurantId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return menuItemsAsync.when(
      data: (allItems) {
        final filteredItems = allItems
            .where((item) => item.category == currentCategory)
            .toList();

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 60, color: isDark ? Colors.grey[700] : Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No $currentCategory items available',
                  style: TextStyle(color: subtextColor),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _moveToNextCategory,
                  child: const Text('Skip to Next Category'),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                ? 2
                : 1;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return _MenuItemCard(
                  item: filteredItems[index],
                  onAdd: () => _addItem(filteredItems[index]),
                  onRemove: () => _removeItem(filteredItems[index]),
                  quantity: _getItemQuantity(filteredItems[index]),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCurrentOrderBar() {
    final currentOrderTotal = _getCurrentOrderSubtotal();
    final itemCount = _getCurrentOrderItemCount();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    if (itemCount == 0) return const SizedBox.shrink();

    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$itemCount items in current order',
                style: TextStyle(fontSize: 14, color: subtextColor),
              ),
              Text(
                '₦${currentOrderTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showCurrentOrderDetails(),
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text('View', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final currentCategoryIndex = availableCategories.indexOf(currentCategory);
    final isLastCategory = currentCategoryIndex >= availableCategories.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (currentCategoryIndex > 0)
            TextButton.icon(
              onPressed: _moveToPreviousCategory,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: isLastCategory ? _completeCurrentOrder : _moveToNextCategory,
            icon: Icon(isLastCategory ? Icons.check : Icons.arrow_forward,
                color: Colors.white),
            label: Text(
              isLastCategory ? 'Complete Order' : 'Next Category',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAGE 3: ORDER SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOrderSummary() {
    return MultiOrderCheckoutScreen(
      orders: completedOrders,
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      onDuplicateOrder: _duplicateOrder,
      onEditOrder: _editOrder,
      onDeleteOrder: _deleteOrder,
    );

  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _addItem(MenuItem item) {
    setState(() {
      final orderItem = OrderItem(
        menuItemId: item.id,
        name: item.name,
        price: item.price,
        quantity: 1,
      );

      // Handle pack separately (only one pack per order)
      if (item.subCategory == 'Pack') {
        if (currentPackItem?.menuItemId == item.id) {
          // Increment quantity
          currentPackItem = currentPackItem!.copyWith(
            quantity: currentPackItem!.quantity + 1,
          );
        } else {
          // Replace with new pack
          currentPackItem = orderItem;
        }
        return;
      }

      // Add to appropriate category
      switch (currentCategory) {
        case 'Food':
          final existingIndex = currentFoodItems.indexWhere(
                (i) => i.menuItemId == item.id,
          );
          if (existingIndex >= 0) {
            currentFoodItems[existingIndex] = currentFoodItems[existingIndex]
                .copyWith(quantity: currentFoodItems[existingIndex].quantity + 1);
          } else {
            currentFoodItems.add(orderItem);
          }
          break;
        case 'Drink':
          final existingIndex = currentDrinkItems.indexWhere(
                (i) => i.menuItemId == item.id,
          );
          if (existingIndex >= 0) {
            currentDrinkItems[existingIndex] = currentDrinkItems[existingIndex]
                .copyWith(quantity: currentDrinkItems[existingIndex].quantity + 1);
          } else {
            currentDrinkItems.add(orderItem);
          }
          break;
        case 'Dessert':
          final existingIndex = currentDessertItems.indexWhere(
                (i) => i.menuItemId == item.id,
          );
          if (existingIndex >= 0) {
            currentDessertItems[existingIndex] = currentDessertItems[existingIndex]
                .copyWith(quantity: currentDessertItems[existingIndex].quantity + 1);
          } else {
            currentDessertItems.add(orderItem);
          }
          break;
      }
    });
  }

  void _removeItem(MenuItem item) {
    setState(() {
      // Handle pack
      if (item.subCategory == 'Pack' && currentPackItem?.menuItemId == item.id) {
        if (currentPackItem!.quantity > 1) {
          currentPackItem = currentPackItem!.copyWith(
            quantity: currentPackItem!.quantity - 1,
          );
        } else {
          currentPackItem = null;
        }
        return;
      }

      // Remove from appropriate category
      switch (currentCategory) {
        case 'Food':
          final index =
          currentFoodItems.indexWhere((i) => i.menuItemId == item.id);
          if (index >= 0) {
            if (currentFoodItems[index].quantity > 1) {
              currentFoodItems[index] = currentFoodItems[index]
                  .copyWith(quantity: currentFoodItems[index].quantity - 1);
            } else {
              currentFoodItems.removeAt(index);
            }
          }
          break;
        case 'Drink':
          final index =
          currentDrinkItems.indexWhere((i) => i.menuItemId == item.id);
          if (index >= 0) {
            if (currentDrinkItems[index].quantity > 1) {
              currentDrinkItems[index] = currentDrinkItems[index]
                  .copyWith(quantity: currentDrinkItems[index].quantity - 1);
            } else {
              currentDrinkItems.removeAt(index);
            }
          }
          break;
        case 'Dessert':
          final index =
          currentDessertItems.indexWhere((i) => i.menuItemId == item.id);
          if (index >= 0) {
            if (currentDessertItems[index].quantity > 1) {
              currentDessertItems[index] = currentDessertItems[index]
                  .copyWith(quantity: currentDessertItems[index].quantity - 1);
            } else {
              currentDessertItems.removeAt(index);
            }
          }
          break;
      }
    });
  }

  int _getItemQuantity(MenuItem item) {
    if (item.subCategory == 'Pack') {
      return currentPackItem?.menuItemId == item.id
          ? currentPackItem!.quantity
          : 0;
    }

    switch (currentCategory) {
      case 'Food':
        final found = currentFoodItems.firstWhere(
              (i) => i.menuItemId == item.id,
          orElse: () =>
              OrderItem(menuItemId: '', name: '', price: 0, quantity: 0),
        );
        return found.quantity;
      case 'Drink':
        final found = currentDrinkItems.firstWhere(
              (i) => i.menuItemId == item.id,
          orElse: () =>
              OrderItem(menuItemId: '', name: '', price: 0, quantity: 0),
        );
        return found.quantity;
      case 'Dessert':
        final found = currentDessertItems.firstWhere(
              (i) => i.menuItemId == item.id,
          orElse: () =>
              OrderItem(menuItemId: '', name: '', price: 0, quantity: 0),
        );
        return found.quantity;
      default:
        return 0;
    }
  }

  double _getCurrentOrderSubtotal() {
    double total = 0;
    total += currentFoodItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    total += currentDrinkItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    total += currentDessertItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    if (currentPackItem != null) {
      total += currentPackItem!.totalPrice;
    }
    return total;
  }

  int _getCurrentOrderItemCount() {
    int count = 0;
    count += currentFoodItems.fold(0, (sum, item) => sum + item.quantity);
    count += currentDrinkItems.fold(0, (sum, item) => sum + item.quantity);
    count += currentDessertItems.fold(0, (sum, item) => sum + item.quantity);
    if (currentPackItem != null) {
      count += currentPackItem!.quantity;
    }
    return count;
  }

  void _moveToNextCategory() {
    final currentIndex = availableCategories.indexOf(currentCategory);
    if (currentIndex < availableCategories.length - 1) {
      setState(() {
        currentCategory = availableCategories[currentIndex + 1];
      });
    }
  }

  void _moveToPreviousCategory() {
    final currentIndex = availableCategories.indexOf(currentCategory);
    if (currentIndex > 0) {
      setState(() {
        currentCategory = availableCategories[currentIndex - 1];
      });
    }
  }

  void _completeCurrentOrder() {
    // Save current order
    final order = IndividualOrder(
      foodItems: List.from(currentFoodItems),
      drinkItems: List.from(currentDrinkItems),
      dessertItems: List.from(currentDessertItems),
      packItem: currentPackItem,
    );

    setState(() {
      completedOrders.add(order);

      // Reset for next order
      currentFoodItems.clear();
      currentDrinkItems.clear();
      currentDessertItems.clear();
      currentPackItem = null;

      // Move to next order or summary
      if (currentOrderIndex + 1 < totalOrders) {
        currentOrderIndex++;
        currentCategory = availableCategories.first;
      } else {
        currentStage = OrderStage.summary;
      }
    });
  }

  void _duplicateOrder(int index) {
    setState(() {
      completedOrders.add(completedOrders[index]);
      totalOrders++;
    });
  }

  void _editOrder(int index) {
    setState(() {
      final order = completedOrders[index];
      currentFoodItems = List.from(order.foodItems);
      currentDrinkItems = List.from(order.drinkItems);
      currentDessertItems = List.from(order.dessertItems);
      currentPackItem = order.packItem;

      completedOrders.removeAt(index);
      currentOrderIndex = index;
      currentCategory = availableCategories.first;
      currentStage = OrderStage.ordering;
    });
  }

  void _deleteOrder(int index) {
    setState(() {
      completedOrders.removeAt(index);
      totalOrders--;
      if (completedOrders.isEmpty) {
        currentStage = OrderStage.selectCount;
        totalOrders = 1;
      }
    });
  }

  void _showCurrentOrderDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    // Show dialog with current order items
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Current Order', style: TextStyle(color: textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentFoodItems.isNotEmpty) ...[
                Text('Food:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ...currentFoodItems.map((item) => Text('${item.quantity}x ${item.name}', style: TextStyle(color: textColor))),
                const SizedBox(height: 8),
              ],
              if (currentDrinkItems.isNotEmpty) ...[
                Text('Drinks:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ...currentDrinkItems.map((item) => Text('${item.quantity}x ${item.name}', style: TextStyle(color: textColor))),
                const SizedBox(height: 8),
              ],
              if (currentDessertItems.isNotEmpty) ...[
                Text('Desserts:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ...currentDessertItems.map((item) => Text('${item.quantity}x ${item.name}', style: TextStyle(color: textColor))),
                const SizedBox(height: 8),
              ],
              if (currentPackItem != null) ...[
                Text('Pack:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text('${currentPackItem!.quantity}x ${currentPackItem!.name}', style: TextStyle(color: textColor)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrderingHelp() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('How to Order', style: TextStyle(color: textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Browse each category (Food, Drink, Dessert)', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              Text('2. Add items you want from each category', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              Text('3. You can select pack under Food category', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              Text('4. Complete the order when done', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              Text('5. If making multiple orders, repeat the process', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              Text('6. Minimum order: ₦500 (excluding pack)', style: TextStyle(color: textColor)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MENU ITEM CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final int quantity;

  const _MenuItemCard({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.restaurant, size: 60, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
            ),
          ),

          // Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '₦',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    item.price.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  // Add/Remove buttons
                  if (quantity == 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add',
                            style: TextStyle(color: Colors.white)),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            onPressed: onRemove,
                            padding: EdgeInsets.zero,
                          ),
                          Text(
                            quantity.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: onAdd,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum OrderStage {
  selectCount,
  ordering,
  summary,
}
