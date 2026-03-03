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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

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
                return Center(child: Text('Profile not found', style: TextStyle(color: textColor)));
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
                    Text(
                      'Earnings Summary',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
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
                                  context,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildEarningsCard(
                                  'Wallet Balance',
                                  '₦${walletBalance.toStringAsFixed(0)}',
                                  Icons.account_balance_wallet,
                                  Colors.blue,
                                  context,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildEarningsCard(
                                  'Total Deliveries',
                                  totalDeliveries.toString(),
                                  Icons.local_shipping,
                                  Colors.orange,
                                  context,
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
                                context,
                              ),
                              const SizedBox(height: 12),
                              _buildEarningsCard(
                                'Wallet Balance',
                                '₦${walletBalance.toStringAsFixed(0)}',
                                Icons.account_balance_wallet,
                                Colors.blue,
                                context,
                              ),
                              const SizedBox(height: 12),
                              _buildEarningsCard(
                                'Total Deliveries',
                                totalDeliveries.toString(),
                                Icons.local_shipping,
                                Colors.orange,
                                context,
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
                        Text(
                          'Delivery History',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
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
      String label, String value, IconData icon, Color color, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Card(
      color: cardColor,
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
              style: TextStyle(
                fontSize: 14,
                color: subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return deliveriesAsync.when(
      data: (deliveries) {
        final completedDeliveries = deliveries
            .where((d) => d.status == 'delivered' || d.status == 'completed')
            .toList();

        if (completedDeliveries.isEmpty) {
          return Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 60, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No delivery history yet',
                      style: TextStyle(color: subtextColor),
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
              color: cardColor,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completedDeliveries.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey[700] : null),
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
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('Error: $error', style: TextStyle(color: textColor))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

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
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('To: ${order.deliveryLocation}', style: TextStyle(color: subtextColor)),
          const SizedBox(height: 2),
          Text(
            order.deliveredAt != null
                ? DateFormat('MMM dd, yyyy - hh:mm a')
                    .format(order.deliveredAt!)
                : DateFormat('MMM dd, yyyy').format(order.createdAt),
            style: TextStyle(fontSize: 12, color: subtextColor),
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
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
