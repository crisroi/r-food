import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:r_foods/providers/restaurant_provider.dart';

class RestaurantSettingsScreen extends ConsumerStatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  ConsumerState<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState
    extends ConsumerState<RestaurantSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();

  String? openTime;
  String? closeTime;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(myRestaurantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: restaurantAsync.when(
            data: (restaurant) {
              if (restaurant == null) {
                return const Center(
                  child: Text('Restaurant not found'),
                );
              }

              // Initialize controllers
              if (nameController.text.isEmpty) {
                nameController.text = restaurant.restaurantName ?? '';
                locationController.text = restaurant.location ?? '';
                openTime = restaurant.operatingHours?['openTime'];
                closeTime = restaurant.operatingHours?['closeTime'];
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Info Section
                      const Text(
                        'Restaurant Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Restaurant Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.restaurant),
                                ),
                                validator: (v) => v?.isEmpty ?? true
                                    ? 'Enter restaurant name'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location (Optional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                  hintText: 'e.g., Student Union, Block A',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Operating Hours Section
                      const Text(
                        'Operating Hours',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive layout for time pickers
                              final isWide = constraints.maxWidth > 500;
                              
                              if (isWide) {
                                // Desktop: Side by side
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimePicker(
                                        label: 'Opening Time',
                                        value: openTime,
                                        onChanged: (v) =>
                                            setState(() => openTime = v),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimePicker(
                                        label: 'Closing Time',
                                        value: closeTime,
                                        onChanged: (v) =>
                                            setState(() => closeTime = v),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Mobile: Stacked
                                return Column(
                                  children: [
                                    _buildTimePicker(
                                      label: 'Opening Time',
                                      value: openTime,
                                      onChanged: (v) =>
                                          setState(() => openTime = v),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTimePicker(
                                      label: 'Closing Time',
                                      value: closeTime,
                                      onChanged: (v) =>
                                          setState(() => closeTime = v),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Restaurant Info Card (Read-only)
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _infoRow(
                                'Owner Name',
                                restaurant.fullName,
                                Icons.person,
                              ),
                              const Divider(height: 24),
                              _infoRow(
                                'Email',
                                restaurant.email,
                                Icons.email,
                              ),
                              const Divider(height: 24),
                              _infoRow(
                                'Phone',
                                restaurant.phoneNumber,
                                Icons.phone,
                              ),
                              const Divider(height: 24),
                              _infoRow(
                                'Max Menu Items',
                                restaurant.maxMenuItems?.toString() ?? '—',
                                Icons.restaurant_menu,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          final formattedTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(formattedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          value ?? 'Select Time',
          style: TextStyle(
            color: value == null ? Colors.grey : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
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
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    if (openTime == null || closeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set operating hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      await ref.read(restaurantServiceProvider).updateRestaurantInfo(
            restaurantId: user.uid,
            restaurantName: nameController.text.trim(),
            location: locationController.text.trim().isEmpty
                ? null
                : locationController.text.trim(),
            operatingHours: {
              'openTime': openTime!,
              'closeTime': closeTime!,
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
