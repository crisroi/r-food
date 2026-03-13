import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:r_foods/providers/restaurant_provider.dart';
import 'package:r_foods/providers/cart_provider.dart';
import 'package:r_foods/models/user_model.dart';
import 'package:r_foods/screens/customer/multi_order_flow_screen.dart';
import 'package:r_foods/screens/customer/cart_screen.dart';
import 'package:r_foods/screens/customer/my_orders_screen.dart';
import 'package:r_foods/screens/drawer.dart';

class CustomerDashboard extends ConsumerWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final cartItemCount = ref.watch(cartTotalItemsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: Text('R-Foods', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          // Cart icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: textColor),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
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
                      cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: buildDrawer(context, isDark, textColor, 'customer'),
      body: SafeArea(
        child: restaurantsAsync.when(
          data: (restaurants) {
            if (restaurants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant, size: 80, color: subtextColor),
                    const SizedBox(height: 16),
                    Text(
                      'No restaurants available yet',
                      style: TextStyle(fontSize: 18, color: subtextColor),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                // Highly responsive column calculation
                int crossAxisCount = 1;
                if (constraints.maxWidth > 1400) {
                  crossAxisCount = 5;
                } else if (constraints.maxWidth > 1100) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth > 800) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth > 550) {
                  crossAxisCount = 2;
                }

                // Adjust aspect ratio based on width to prevent stretching
                double aspectRatio = 1.1;
                if (constraints.maxWidth > 1100) {
                  aspectRatio = 1.0;
                } else if (constraints.maxWidth < 400) {
                  aspectRatio = 1.2;
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Restaurants',
                        style: TextStyle(
                          fontSize: constraints.maxWidth > 600 ? 28 : 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: aspectRatio,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: restaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = restaurants[index];
                            return _RestaurantCard(restaurant: restaurant);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error', style: TextStyle(color: textColor)),
          ),
        ),
      ),
    );
  }

}

class _RestaurantCard extends StatelessWidget {
  final UserModel restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final isOpen = restaurant.isOpen ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isSmallCard = cardWidth < 200;

        return Card(
          color: cardColor,
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: isOpen
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiOrderFlowScreen(
                          restaurantId: restaurant.uid,
                          restaurantName: restaurant.restaurantName ?? 'Restaurant',
                        ),
                      ),
                    )
                : null,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top part: Logo/Image
                    Expanded(
                      flex: 3,
                      child: restaurant.restaurantLogoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: restaurant.restaurantLogoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.restaurant, color: Colors.orange),
                              ),
                            )
                          : Container(
                              color: Colors.orange.withOpacity(0.1),
                              child: Icon(
                                Icons.restaurant,
                                size: isSmallCard ? 30 : 50,
                                color: Colors.orange,
                              ),
                            ),
                    ),
                    // Bottom part: Info
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallCard ? 8 : 12,
                          vertical: isSmallCard ? 4 : 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              restaurant.restaurantName ?? 'Restaurant',
                              style: TextStyle(
                                fontSize: isSmallCard ? 14 : 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (restaurant.location != null)
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: isSmallCard ? 12 : 14, color: subtextColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      restaurant.location!,
                                      style: TextStyle(
                                        fontSize: isSmallCard ? 10 : 12,
                                        color: subtextColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (restaurant.operatingHours != null && !isSmallCard) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: subtextColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${restaurant.operatingHours!['openTime']} - ${restaurant.operatingHours!['closeTime']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Open/Closed badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                      ],
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Closed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

                // Closed overlay
                if (!isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'CLOSED',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
