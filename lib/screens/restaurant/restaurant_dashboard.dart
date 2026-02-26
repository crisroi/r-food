import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:r_foods/providers/restaurant_provider.dart';
import 'package:r_foods/providers/order_provider.dart';
import 'package:r_foods/screens/restaurant/menu_management_screen.dart';
import 'package:r_foods/screens/restaurant/restaurant_orders_screen.dart';
import 'package:r_foods/screens/restaurant/restaurant_settings_screen.dart';

class RestaurantDashboard extends ConsumerStatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  ConsumerState<RestaurantDashboard> createState() =>
      _RestaurantDashboardState();
}

class _RestaurantDashboardState extends ConsumerState<RestaurantDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(myRestaurantProvider);
    final pendingOrdersAsync = ref.watch(restaurantPendingOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Restaurant Dashboard'),
        actions: [
          // Toggle open/close
          restaurantAsync.when(
            data: (restaurant) {
              if (restaurant == null) return const SizedBox();
              return Row(
                children: [
                  Text(
                    restaurant.isOpen ?? false ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: restaurant.isOpen ?? false
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: restaurant.isOpen ?? false,
                    onChanged: (value) => _toggleRestaurantStatus(value),
                    activeColor: Colors.green,
                  ),
                ],
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: restaurantAsync.when(
        data: (restaurant) {
          if (restaurant == null) {
            return const Center(
              child: Text('Restaurant profile not found'),
            );
          }

          return IndexedStack(
            index: _selectedIndex,
            children: [
              _buildOverviewTab(restaurant),
              const MenuManagementScreen(),
              const RestaurantOrdersScreen(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Stack(
              children: [
                const Icon(Icons.receipt_long),
                pendingOrdersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) return const SizedBox();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          orders.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
            label: 'Orders',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(restaurant) {
    final pendingOrdersAsync = ref.watch(restaurantPendingOrdersProvider);
    final activeOrdersAsync = ref.watch(restaurantActiveOrdersProvider);
    final myMenuItemsAsync = ref.watch(myMenuItemsProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Info Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.restaurantName ?? 'Restaurant',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (restaurant.location != null)
                                  Text(
                                    restaurant.location!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RestaurantSettingsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Operating Hours',
                              restaurant.operatingHours != null
                                  ? '${restaurant.operatingHours!['openTime']} - ${restaurant.operatingHours!['closeTime']}'
                                  : 'Not set',
                              Icons.access_time,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Max Menu Items',
                              restaurant.maxMenuItems?.toString() ?? '—',
                              Icons.restaurant_menu,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Cards
              const Text(
                'Quick Stats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: isWide
                            ? (constraints.maxWidth - 32) / 3
                            : constraints.maxWidth,
                        child: pendingOrdersAsync.when(
                          data: (orders) => _buildStatCard(
                            'Pending Orders',
                            orders.length.toString(),
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                          loading: () => _buildStatCard(
                            'Pending Orders',
                            '...',
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                          error: (_, __) => _buildStatCard(
                            'Pending Orders',
                            'Error',
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isWide
                            ? (constraints.maxWidth - 32) / 3
                            : constraints.maxWidth,
                        child: activeOrdersAsync.when(
                          data: (orders) => _buildStatCard(
                            'Active Orders',
                            orders.length.toString(),
                            Icons.fastfood,
                            Colors.blue,
                          ),
                          loading: () => _buildStatCard(
                            'Active Orders',
                            '...',
                            Icons.fastfood,
                            Colors.blue,
                          ),
                          error: (_, __) => _buildStatCard(
                            'Active Orders',
                            'Error',
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isWide
                            ? (constraints.maxWidth - 32) / 3
                            : constraints.maxWidth,
                        child: myMenuItemsAsync.when(
                          data: (items) => _buildStatCard(
                            'Menu Items',
                            items.length.toString(),
                            Icons.menu_book,
                            Colors.green,
                          ),
                          loading: () => _buildStatCard(
                            'Menu Items',
                            '...',
                            Icons.menu_book,
                            Colors.green,
                          ),
                          error: (_, __) => _buildStatCard(
                            'Menu Items',
                            'Error',
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 1),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Menu Item'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 2),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Orders'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RestaurantSettingsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRestaurantStatus(bool isOpen) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await ref
          .read(restaurantServiceProvider)
          .toggleRestaurantStatus(user.uid, isOpen);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOpen
                  ? 'Restaurant is now open for orders'
                  : 'Restaurant is now closed',
            ),
            backgroundColor: isOpen ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
