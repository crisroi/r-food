import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWideScreen ? 40.0 : 20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWideScreen ? 800 : double.infinity,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    size: isWideScreen ? 100 : 80,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sign Up As',
                    style: TextStyle(
                      fontSize: isWideScreen ? 32 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose your account type',
                    style: TextStyle(
                      fontSize: isWideScreen ? 18 : 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: isWideScreen ? 60 : 50),

                  // For wide screens, show cards in a grid
                  if (isWideScreen)
                    _buildWideScreenLayout(context)
                  else
                    _buildMobileLayout(context),

                  SizedBox(height: isWideScreen ? 50 : 40),

                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: isWideScreen ? 18 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildRoleCard(
          context,
          title: 'Customer',
          description: 'Order food from campus restaurants',
          icon: Icons.shopping_bag,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/customerSignup'),
        ),
        const SizedBox(height: 20),
        _buildRoleCard(
          context,
          title: 'Restaurant',
          description: 'Manage your restaurant and menu',
          icon: Icons.restaurant,
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, '/restaurantSignup'),
        ),
        const SizedBox(height: 20),
        _buildRoleCard(
          context,
          title: 'Delivery Partner',
          description: 'Deliver food and earn money',
          icon: Icons.delivery_dining,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/deliveryPartnerSignup'),
        ),
      ],
    );
  }

  Widget _buildWideScreenLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildRoleCard(
            context,
            title: 'Customer',
            description: 'Order food from campus restaurants',
            icon: Icons.shopping_bag,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/customerSignup'),
            isWideScreen: true,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildRoleCard(
            context,
            title: 'Restaurant',
            description: 'Manage your restaurant and menu',
            icon: Icons.restaurant,
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/restaurantSignup'),
            isWideScreen: true,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildRoleCard(
            context,
            title: 'Delivery Partner',
            description: 'Deliver food and earn money',
            icon: Icons.delivery_dining,
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/deliveryPartnerSignup'),
            isWideScreen: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isWideScreen = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(isWideScreen ? 30.0 : 20.0),
          child: isWideScreen
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 50,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
