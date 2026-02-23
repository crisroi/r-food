import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final dN = ref.watch(displayName);

    print(dN);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("$dN Dashboard"),
        actions: [
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
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }

          // Responsive layout: Grid for web, List for mobile
          return LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 600;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: isWide
                    ? GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: _foodItems.map((food) {
                          return FoodCard(food: food);
                        }).toList(),
                      )
                    : ListView.builder(
                        itemCount: _foodItems.length,
                        itemBuilder: (context, index) {
                          return FoodCard(food: _foodItems[index]);
                        },
                      ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// Fixed food items with proper emoji encoding
final List<Map<String, dynamic>> _foodItems = [
  {"name": "Pizza", "price": 12.99, "image": "🍕"},
  {"name": "Burger", "price": 9.99, "image": "🍔"},
  {"name": "Sushi", "price": 15.99, "image": "🍣"},
  {"name": "Salad", "price": 7.99, "image": "🥗"},
  {"name": "Ice Cream", "price": 5.99, "image": "🍨"},
  {"name": "Pasta", "price": 11.99, "image": "🍝"},
  {"name": "Tacos", "price": 8.99, "image": "🌮"},
  {"name": "Ramen", "price": 13.99, "image": "🍜"},
];

class FoodCard extends StatelessWidget {
  final Map<String, dynamic> food;
  const FoodCard({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(food['image'], style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(food['name'],
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("\$${food['price']}",
                style: const TextStyle(fontSize: 16, color: Colors.green)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${food['name']} ordered!")),
                );
              },
              child: const Text("Order"),
            ),
          ],
        ),
      ),
    );
  }
}
