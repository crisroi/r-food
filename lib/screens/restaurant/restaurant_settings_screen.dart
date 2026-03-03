// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:r_foods/providers/restaurant_provider.dart';
import '../../services/cloudinary_service.dart';
import 'package:flutter/services.dart';

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

  XFile? logoFile;
  Uint8List? logoBytes;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(myRestaurantProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurant Settings', style: TextStyle(color: textColor)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: restaurantAsync.when(
            data: (restaurant) {
              if (restaurant == null) {
                return Center(
                  child: Text('Restaurant not found', style: TextStyle(color: textColor)),
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
                      Text(
                        'Restaurant Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: cardColor,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: nameController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Restaurant Name',
                                  labelStyle: TextStyle(color: subtextColor),
                                  border: const OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                  prefixIcon: Icon(Icons.restaurant, color: subtextColor),
                                ),
                                validator: (v) => v?.isEmpty ?? true
                                    ? 'Enter restaurant name'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              Text('Restaurant Logo',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _pickLogo,
                                child: Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: logoBytes != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(logoBytes!, fit: BoxFit.cover),
                                  )
                                      : restaurant.restaurantLogoUrl != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      restaurant.restaurantLogoUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                      : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 48, color: subtextColor),
                                      const SizedBox(height: 8),
                                      Text('Tap to add logo (optional)', style: TextStyle(color: subtextColor)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: locationController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Location (Optional)',
                                  labelStyle: TextStyle(color: subtextColor),
                                  border: const OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                  prefixIcon: Icon(Icons.location_on, color: subtextColor),
                                  hintText: 'e.g., Student Union, Block A',
                                  hintStyle: TextStyle(color: subtextColor?.withOpacity(0.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Operating Hours Section
                      Text(
                        'Operating Hours',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: cardColor,
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
                                        textColor: textColor,
                                        subtextColor: subtextColor!,
                                        borderColor: borderColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimePicker(
                                        label: 'Closing Time',
                                        value: closeTime,
                                        onChanged: (v) =>
                                            setState(() => closeTime = v),
                                        textColor: textColor,
                                        subtextColor: subtextColor,
                                        borderColor: borderColor,
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
                                      textColor: textColor,
                                      subtextColor: subtextColor!,
                                      borderColor: borderColor,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTimePicker(
                                      label: 'Closing Time',
                                      value: closeTime,
                                      onChanged: (v) =>
                                          setState(() => closeTime = v),
                                      textColor: textColor,
                                      subtextColor: subtextColor!,
                                      borderColor: borderColor,
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
                      Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: cardColor,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _infoRow(
                                'Owner Name',
                                restaurant.fullName,
                                Icons.person,
                                textColor,
                                subtextColor!,
                              ),
                              Divider(height: 24, color: isDark ? Colors.grey[700] : null),
                              _infoRow(
                                'Email',
                                restaurant.email,
                                Icons.email,
                                textColor,
                                subtextColor,
                              ),
                              Divider(height: 24, color: isDark ? Colors.grey[700] : null),
                              _infoRow(
                                'Phone',
                                restaurant.phoneNumber,
                                Icons.phone,
                                textColor,
                                subtextColor,
                              ),
                              Divider(height: 24, color: isDark ? Colors.grey[700] : null),
                              _infoRow(
                                'Max Menu Items',
                                restaurant.maxMenuItems?.toString() ?? '—',
                                Icons.restaurant_menu,
                                textColor,
                                subtextColor,
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
            error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: textColor))),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String? value,
    required Function(String?) onChanged,
    required Color textColor,
    required Color subtextColor,
    required Color borderColor,
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
          labelStyle: TextStyle(color: subtextColor),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          prefixIcon: Icon(Icons.access_time, color: subtextColor),
        ),
        child: Text(
          value ?? 'Select Time',
          style: TextStyle(
            color: value == null ? subtextColor : textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, Color textColor, Color subtextColor) {
    return Row(
      children: [
        Icon(icon, color: subtextColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
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

      final currentRestaurant = ref.read(myRestaurantProvider).value;
      String? logoUrl = currentRestaurant?.restaurantLogoUrl;

      // If a new logo was picked, upload it and update the URL
      if (logoFile != null && logoBytes != null) {
        logoUrl = await CloudinaryService().uploadImageFromBytes(
          bytes: logoBytes!,
          fileName: logoFile!.name,
          folder: 'restaurant_logos',
        );
      }

      // Pass the correct logoUrl to the update method
      await ref.read(restaurantServiceProvider).updateRestaurantInfo(
            restaurantId: user.uid,
            restaurantName: nameController.text.trim(),
            restaurantLogoUrl: logoUrl, // Corrected from "url"
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

  Future<void> _pickLogo() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        logoFile = picked;
        logoBytes = bytes;
      });
    }
  }
}
