import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'customer/my_orders_screen.dart';

Widget _buildDrawer(
    BuildContext context, bool isDark, Color textColor, String role) {
  final user = FirebaseAuth.instance.currentUser;
  // final userRole = ref.read(role);
  // print(userRole);

  return Drawer(
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    child: Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: const BoxDecoration(color: Colors.orange),
          accountName: Text(user?.displayName ?? "Guest User",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          accountEmail: Text(user?.email ?? ""),
          currentAccountPicture: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.orange, size: 40),
          ),
        ),
        if (role == "customer") ...[
          Column(
            children: [
              ListTile(
                leading: Icon(Icons.home, color: textColor),
                title: Text('Home', style: TextStyle(color: textColor)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.receipt_long, color: textColor),
                title: Text('My Orders', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyOrdersScreen()));
                },
              ),
            ],
          )
        ],
        const Spacer(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

const buildDrawer = _buildDrawer;
