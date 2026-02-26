import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:r_foods/providers/order_provider.dart';
import 'package:r_foods/models/order_model.dart';
import 'package:intl/intl.dart';

class DeliveryEarningsScreen extends ConsumerWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
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

              final totalEarnings = (data['totalEarnings'] ?? 0.0).toDouble();
              final walletBalance = (data['walletBalance'] ?? 0.0).toDouble();
              final totalDeliveries = data['totalDeliveries'] ?? 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings Summary
                    const Text(
                      'Earnings Summary',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;

                        if (isWide) {
                          // Desktop: 3 cards in a row
                          return Row(
                            children: [
                              Expanded(
                                child: _buildEarningsCard(
                                  'Total Earned',
                                  '₦${totalEarnings.toStringAsFixed(0)}',
                                  Icons.payments,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildEarningsCard(
                                  'Wallet Balance',
                                  '₦${walletBalance.toStringAsFixed(0)}',
                                  Icons.account_balance_wallet,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildEarningsCard(
                                  'Total Deliveries',
                                  totalDeliveries.toString(),
                                  Icons.local_shipping,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Mobile: Stacked cards
                          return Column(
                            children: [
                              _buildEarningsCard(
                                'Total Earned',
                                '₦${totalEarnings.toStringAsFixed(0)}',
                                Icons.payments,
                                Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildEarningsCard(
                                'Wallet Balance',
                                '₦${walletBalance.toStringAsFixed(0)}',
                                Icons.account_balance_wallet,
                                Colors.blue,
                              ),
                              const SizedBox(height: 12),
                              _buildEarningsCard(
                                'Total Deliveries',
                                totalDeliveries.toString(),
                                Icons.local_shipping,
                                Colors.orange,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // Delivery History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery History',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {}, // TODO: Export/Download
                          icon: const Icon(Icons.download),
                          label: const Text('Export'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DeliveryHistoryList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryHistoryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveryPartnerOrdersProvider);

    return deliveriesAsync.when(
      data: (deliveries) {
        final completedDeliveries = deliveries
            .where((d) => d.status == 'delivered' || d.status == 'completed')
            .toList();

        if (completedDeliveries.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No delivery history yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completedDeliveries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final order = completedDeliveries[index];
                  return _DeliveryHistoryItem(
                    order: order,
                    isWide: isWide,
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _DeliveryHistoryItem extends StatelessWidget {
  final OrderModel order;
  final bool isWide;

  const _DeliveryHistoryItem({
    required this.order,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 16,
        vertical: isWide ? 12 : 8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.green),
      ),
      title: Text(
        order.restaurantName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('To: ${order.deliveryLocation}'),
          const SizedBox(height: 2),
          Text(
            order.deliveredAt != null
                ? DateFormat('MMM dd, yyyy - hh:mm a')
                    .format(order.deliveredAt!)
                : DateFormat('MMM dd, yyyy').format(order.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₦${order.deliveryFee.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          if (order.deliveryPartnerRating != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Colors.orange),
                const SizedBox(width: 2),
                Text(
                  order.deliveryPartnerRating.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
