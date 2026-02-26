import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:r_foods/screens/admin/admin_dashboard.dart';
import 'package:r_foods/screens/customer/customer_signup.dart';
import 'package:r_foods/screens/customerDashboard.dart';
import 'package:r_foods/screens/delivery/delivery_partner_signup.dart';
import 'package:r_foods/screens/login.dart';
import 'package:r_foods/screens/restaurant/restaurant_dashboard.dart';
import 'package:r_foods/screens/restaurant/restaurant_signup.dart';
import 'package:r_foods/screens/role_selection_screen.dart';
import 'package:r_foods/screens/signup.dart';
import 'package:r_foods/screens/reset_password.dart';

import '../screens/customer/customer_dashboard.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "R-Food",
      debugShowCheckedModeBanner: false,

      // Light theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CupertinoColors.activeOrange,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CupertinoColors.activeOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      // Dark theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CupertinoColors.activeOrange,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CupertinoColors.activeOrange,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      // Auto-switch based on system setting
      themeMode: ThemeMode.system,

      home: const RoleSelectionScreen(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/signupSelection': (_) => const RoleSelectionScreen(),
        '/resetPassword': (_) => const ResetPasswordPage(),
        '/customerSignup': (_) => const CustomerSignup(),
        '/restaurantSignup': (_) => const RestaurantSignup(),
        '/deliveryPartnerSignup': (_) => const DeliveryPartnerSignup(),
        '/customerDashboard': (_) => const CustomerDashboard(),
        '/adminDashboard': (_) => const AdminDashboard(),
        '/restaurantDashboard': (_) => const RestaurantDashboard(),
        // TODO: Add these routes when implementing the dashboards
        // '/restaurantDashboard': (_) => const RestaurantHomePage(),
        // '/deliveryDashboard': (_) => const DeliveryHomePage(),
      },
    );
  }
}
