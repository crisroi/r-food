import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:r_foods/providers/order_provider.dart';
import 'package:r_foods/providers/auth_provider.dart';
import 'package:r_foods/screens/delivery/available_deliveries_screen.dart';
import 'package:r_foods/screens/delivery/my_deliveries_screen.dart';
import 'package:r_foods/screens/delivery/delivery_earnings_screen.dart';

class DeliveryPartnerDashboard extends ConsumerStatefulWidget {
  const DeliveryPartnerDashboard({super.key});

  @override
  ConsumerState<DeliveryPartnerDashboard> createState() =>
      _DeliveryPartnerDashboardState();
}

class _DeliveryPartnerDashboardState
    extends ConsumerState<DeliveryPartnerDashboard> {
  int _selectedIndex = 0;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() => _isAvailable = doc.data()?['isAvailable'] ?? false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDeliveriesAsync = ref.watch(activeDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Delivery Partner'),
        actions: [
          // Availability toggle
          Row(
            children: [
              Text(
                _isAvailable ? 'Available' : 'Offline',
                style: TextStyle(
                  color: _isAvailable ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _isAvailable,
                onChanged: (value) => _toggleAvailability(value),
                activeColor: Colors.green,
              ),
            ],
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(),
          const AvailableDeliveriesScreen(),
          const MyDeliveriesScreen(),
          const DeliveryEarningsScreen(),
        ],
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
          NavigationDestination(
            icon: Stack(
              children: [
                const Icon(Icons.delivery_dining),
                if (_isAvailable)
                  ref.watch(availableDeliveryOrdersProvider).when(
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
            label: 'Available',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment),
            label: 'My Deliveries',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: StreamBuilder<DocumentSnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
              : null,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data?.data() as Map<String, dynamic>?;
            if (data == null) {
              return const Center(child: Text('Profile not found'));
            }

            final totalDeliveries = data['totalDeliveries'] ?? 0;
            final totalEarnings = (data['totalEarnings'] ?? 0.0).toDouble();
            final walletBalance = (data['walletBalance'] ?? 0.0).toDouble();
            final averageRating = (data['averageRating'] ?? 0.0).toDouble();
            final totalRatings = data['totalRatings'] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: data['profileImageUrl'] != null
                                ? NetworkImage(data['profileImageUrl'])
                                : null,
                            child: data['profileImageUrl'] == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${data['firstname']} ${data['lastname']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      averageRating > 0
                                          ? '${averageRating.toStringAsFixed(1)} ($totalRatings ratings)'
                                          : 'No ratings yet',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isAvailable
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isAvailable ? Colors.green : Colors.grey,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isAvailable ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: _isAvailable ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isAvailable ? 'Available' : 'Offline',
                                  style: TextStyle(
                                    color: _isAvailable ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      final isMedium = constraints.maxWidth > 600;
                      final crossAxisCount = isWide ? 4 : isMedium ? 2 : 1;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildStatCard(
                            'Total Deliveries',
                            totalDeliveries.toString(),
                            Icons.local_shipping,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Total Earnings',
                            '₦${totalEarnings.toStringAsFixed(0)}',
                            Icons.payments,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Wallet Balance',
                            '₦${walletBalance.toStringAsFixed(0)}',
                            Icons.account_balance_wallet,
                            Colors.purple,
                          ),
                          _buildStatCard(
                            'Average Rating',
                            averageRating > 0
                                ? averageRating.toStringAsFixed(1)
                                : '—',
                            Icons.star,
                            Colors.orange,
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
                        icon: const Icon(Icons.delivery_dining),
                        label: const Text('View Available Orders'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _selectedIndex = 2),
                        icon: const Icon(Icons.assignment),
                        label: const Text('My Deliveries'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _selectedIndex = 3),
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text('View Earnings'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Availability Notice
                  if (!_isAvailable) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You are currently offline. Turn on availability to start accepting deliveries.',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAvailability(bool isAvailable) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isAvailable': isAvailable});

      setState(() => _isAvailable = isAvailable);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvailable
                  ? 'You are now available for deliveries'
                  : 'You are now offline',
            ),
            backgroundColor: isAvailable ? Colors.green : Colors.orange,
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
