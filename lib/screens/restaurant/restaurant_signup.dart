import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantSignup extends ConsumerStatefulWidget {
  const RestaurantSignup({super.key});

  @override
  ConsumerState<RestaurantSignup> createState() => _RestaurantSignupState();
}

class _RestaurantSignupState extends ConsumerState<RestaurantSignup> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final restaurantNameController = TextEditingController();
  final locationController = TextEditingController();
  final maxMenuItemsController = TextEditingController();

  String? openTime;
  String? closeTime;
  bool trackQuantity = false;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    fNameController.dispose();
    lNameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    restaurantNameController.dispose();
    locationController.dispose();
    maxMenuItemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Sign Up'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth > 600 ? 500 : double.infinity,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Create Restaurant Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Personal Information Section
                    _buildSectionTitle("Personal Information"),
                    _buildTextField(fNameController, "First Name"),
                    _buildTextField(lNameController, "Last Name"),
                    _buildTextField(
                      emailController,
                      "Email",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      phoneController,
                      "Phone Number",
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly]
                    ),
                    _buildTextField(
                      passwordController,
                      "Password",
                      obscureText: true,
                    ),

                    const SizedBox(height: 20),

                    // Restaurant Information Section
                    _buildSectionTitle("Restaurant Information"),
                    _buildTextField(
                      restaurantNameController,
                      "Restaurant Name",
                      required: true,
                    ),
                    _buildTextField(
                      locationController,
                      "Campus Location (Optional)",
                      required: false,
                      helper: "e.g., Student Union, Faculty Building",
                    ),

                    const SizedBox(height: 20),

                    // Operating Hours Section
                    _buildSectionTitle("Operating Hours"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePicker(
                            label: "Opening Time",
                            value: openTime,
                            onChanged: (value) =>
                                setState(() => openTime = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTimePicker(
                            label: "Closing Time",
                            value: closeTime,
                            onChanged: (value) =>
                                setState(() => closeTime = value),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Menu Settings Section
                    _buildSectionTitle("Menu Settings"),
                    _buildTextField(
                      maxMenuItemsController,
                      "Maximum Menu Items",
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      required: true,
                      helper: "How many items can you have on your menu?",
                    ),

                    const SizedBox(height: 10),

                    SwitchListTile(
                      title: const Text("Track Quantity"),
                      subtitle: const Text(
                        "Track exact portions available for each item",
                      ),
                      value: trackQuantity,
                      onChanged: (value) =>
                          setState(() => trackQuantity = value),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                "Create Restaurant Account",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          "Already have an account? Login",
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (phoneController.text.length != 11) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number should be exactly eleven digits'),
              backgroundColor: Colors.red,
            ),
        );
        return;
      }
      if (openTime == null || closeTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select operating hours'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Create user in Firebase Auth
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        User? user = userCredential.user;

        if (user == null) {
          throw Exception("User creation failed");
        }

        // Update display name
        await user.updateDisplayName(
            "${fNameController.text.trim()} ${lNameController.text.trim()}");
        await user.reload();

        // Create user document with restaurant-specific fields
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstname': fNameController.text.trim(),
          'lastname': lNameController.text.trim(),
          'email': emailController.text.trim(),
          'role': 'restaurant',
          'phoneNumber': phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          // Restaurant-specific fields
          'restaurantName': restaurantNameController.text.trim(),
          'location': locationController.text.trim().isEmpty
              ? null
              : locationController.text.trim(),
          'operatingHours': {
            'openTime': openTime,
            'closeTime': closeTime,
          },
          'trackQuantity': trackQuantity,
          'maxMenuItems': int.parse(maxMenuItemsController.text.trim()),
          'isOpen': _isWithinOperatingHours(openTime!, closeTime!),
        });

        if (!mounted) return;

        // Navigate to restaurant dashboard
        Navigator.pushReplacementNamed(context, '/restaurantDashboard');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signup failed: ${e.toString()}'),
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

  bool _isWithinOperatingHours(String openTime, String closeTime) {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return currentTime.compareTo(openTime) >= 0 &&
        currentTime.compareTo(closeTime) <= 0;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepOrange,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool required = true,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return "Enter $label";
          }
          if (label == "Email" && value!.isNotEmpty && !value.contains('@')) {
            return "Enter a valid email";
          }
          if (label == "Password" &&
              value!.isNotEmpty &&
              value.length < 6) {
            return "Password must be at least 6 characters";
          }
          return null;
        },
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          value ?? 'Select Time',
          style: TextStyle(
            color: value == null ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}
