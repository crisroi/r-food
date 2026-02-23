import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:r_foods/services/cloudinary_service.dart';

// ✅ NO dart:io import  — XFile + Uint8List work on every platform

class DeliveryPartnerSignup extends ConsumerStatefulWidget {
  const DeliveryPartnerSignup({super.key});

  @override
  ConsumerState<DeliveryPartnerSignup> createState() =>
      _DeliveryPartnerSignupState();
}

class _DeliveryPartnerSignupState
    extends ConsumerState<DeliveryPartnerSignup> {
  // ── Form ────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ─────────────────────────────────────────────────────────
  final fNameController     = TextEditingController();
  final lNameController     = TextEditingController();
  final emailController     = TextEditingController();
  final phoneController     = TextEditingController();
  final passwordController  = TextEditingController();
  final studentIdController = TextEditingController();
  final courseController    = TextEditingController();
  final blockController     = TextEditingController();
  final roomController      = TextEditingController();

  // ── Picked image info ────────────────────────────────────────────────────
  // XFile holds the path (native) or blob URL (web) and name
  XFile?      profileXFile;
  Uint8List?  profileBytes;

  XFile?      idCardXFile;
  Uint8List?  idCardBytes;

  XFile?      hostelDocXFile;
  Uint8List?  hostelDocBytes;

  // ── Dropdowns ────────────────────────────────────────────────────────────
  String? selectedYear;
  String? selectedHostel;
  String? selectedHostelType;

  bool _isLoading   = false;
  int  _currentStep = 0;

  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker       _picker     = ImagePicker();

  // ── Dispose ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    fNameController.dispose();
    lNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    studentIdController.dispose();
    courseController.dispose();
    blockController.dispose();
    roomController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner Sign Up'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
            // Single Form wraps ALL steps
            child: Form(
              key: _formKey,
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                controlsBuilder: (context, details) => Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      if (_currentStep < 5)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text('Continue'),
                        ),
                      if (_currentStep == 5)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Submit Application'),
                        ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                    ],
                  ),
                ),
                steps: [
                  _step(0, 'Personal Information', _stepPersonalInfo()),
                  _step(1, 'Profile Picture',      _stepProfilePicture()),
                  _step(2, 'Student Verification', _stepStudentVerification()),
                  _step(3, 'Academic Information', _stepAcademicInfo()),
                  _step(4, 'Hostel Information',   _stepHostelInfo()),
                  _step(5, 'Review & Submit',       _stepReview()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Step _step(int index, String title, Widget content) => Step(
    title: Text(title),
    isActive: _currentStep >= index,
    state: _currentStep > index
        ? StepState.complete
        : _currentStep == index
        ? StepState.editing
        : StepState.indexed,
    content: content,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // STEPS
  // ══════════════════════════════════════════════════════════════════════════

  // ── Step 1 ────────────────────────────────────────────────────────────────
  Widget _stepPersonalInfo() => Column(
    children: [
      _field(
          fNameController,
          'First Name',
          icon: Icons.person,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),]
      ),
      _field(
          lNameController,
          'Last Name',
          icon: Icons.person,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),]
      ),
      _field(
        emailController,
        'Email',
        icon: Icons.email,
        keyboardType: TextInputType.emailAddress,
        extraValidator: (v) =>
        v != null && !v.contains('@') ? 'Enter a valid email' : null,
      ),
      _field(
        phoneController,
        'Phone Number',
        icon: Icons.phone,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        extraValidator: (v) => v != null && v.length != 11 ?
            'Phone number should be exactly eleven digits' : null
      ),
      _field(
        passwordController,
        'Password',
        icon: Icons.lock,
        obscureText: true,
        extraValidator: (v) => v != null && v.length < 6
            ? 'Password must be at least 6 characters'
            : null,
      ),
    ],
  );

  // ── Step 2 ────────────────────────────────────────────────────────────────
  Widget _stepProfilePicture() => Column(
    children: [
      const Text(
        'Upload a clear photo of yourself',
        style: TextStyle(fontSize: 15, color: Colors.grey),
      ),
      const SizedBox(height: 20),
      if (profileBytes != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(80),
          child: Image.memory(
            profileBytes!,
            height: 160,
            width: 160,
            fit: BoxFit.cover,
          ),
        ),
      const SizedBox(height: 16),
      _imgBtn(
        label:     profileBytes == null ? 'Select Photo' : 'Change Photo',
        icon:      Icons.camera_alt,
        onPressed: () => _pickImage(_ImgType.profile),
      ),
      if (profileBytes == null)
        _hint('Profile picture is required'),
    ],
  );

  // ── Step 3 ────────────────────────────────────────────────────────────────
  Widget _stepStudentVerification() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _field(
        studentIdController,
        'Student ID Number',
        icon: Icons.badge,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly]
      ),
      const SizedBox(height: 20),
      const Text(
        'Upload a photo of your Student ID Card',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 10),
      if (idCardBytes != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            idCardBytes!,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
      const SizedBox(height: 10),
      _imgBtn(
        label:     idCardBytes == null ? 'Select ID Card Photo' : 'Change Photo',
        icon:      Icons.card_membership,
        onPressed: () => _pickImage(_ImgType.idCard),
      ),
      if (idCardBytes == null)
        _hint('ID card photo is required'),
    ],
  );

  // ── Step 4 ────────────────────────────────────────────────────────────────
  Widget _stepAcademicInfo() => Column(
    children: [
      _field(
        courseController,
        'Course of Study',
        icon:   Icons.school,
        helper: 'e.g., Computer Science, Medicine, Engineering',
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),]
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: selectedYear,
        decoration: InputDecoration(
          labelText:  'Year of Study',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5']
            .map((y) => DropdownMenuItem(value: y, child: Text(y)))
            .toList(),
        onChanged:  (v) => setState(() => selectedYear = v),
        validator:  (v) => v == null ? 'Please select your year' : null,
      ),
    ],
  );

  // ── Step 5 ────────────────────────────────────────────────────────────────
  Widget _stepHostelInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<String>(
        value: selectedHostel,
        decoration: InputDecoration(
          labelText:  'Hostel Name',
          prefixIcon: const Icon(Icons.home),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: ['Main Hostel', 'Extension', 'Engineering Hostel']
            .map((h) => DropdownMenuItem(value: h, child: Text(h)))
            .toList(),
        onChanged:  (v) => setState(() => selectedHostel = v),
        validator:  (v) => v == null ? 'Please select your hostel' : null,
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: selectedHostelType,
        decoration: InputDecoration(
          labelText:  'Hostel Type',
          prefixIcon: const Icon(Icons.wc),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: ['Boys', 'Girls']
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged:  (v) => setState(() => selectedHostelType = v),
        validator:  (v) => v == null ? 'Please select hostel type' : null,
      ),
      const SizedBox(height: 14),
      _field(
        blockController,
        'Block Number',
        icon:   Icons.domain,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
        helper: 'e.g., Block 1, Block 2',
      ),
      _field(
        roomController,
        'Room Number',
        icon:     Icons.door_back_door,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
        required: true,
      ),
      const SizedBox(height: 20),
      const Text(
        'Upload your Hostel Allocation Document',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 10),
      if (hostelDocBytes != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            hostelDocBytes!,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
      const SizedBox(height: 10),
      _imgBtn(
        label:     hostelDocBytes == null ? 'Select Document' : 'Change Document',
        icon:      Icons.document_scanner,
        onPressed: () => _pickImage(_ImgType.hostelDoc),
      ),
      if (hostelDocBytes == null)
        _hint('Hostel allocation document is required'),
    ],
  );

  // ── Step 6 ────────────────────────────────────────────────────────────────
  Widget _stepReview() {
    final hostelLine =
        '${selectedHostel ?? '—'} (${selectedHostelType ?? '—'}) '
        '– Block ${blockController.text}'
        '${roomController.text.isNotEmpty ? ', Room ${roomController.text}' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review your information before submitting.',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        _row('Name',       '${fNameController.text} ${lNameController.text}'),
        _row('Email',       emailController.text),
        _row('Phone',       phoneController.text),
        _row('Student ID',  studentIdController.text),
        _row('Course',      courseController.text),
        _row('Year',        selectedYear ?? '—'),
        _row('Hostel',      hostelLine),
        const Divider(height: 28),
        _row('Profile Picture',
            profileBytes    != null ? '✅ Uploaded' : '❌ Missing'),
        _row('ID Card',
            idCardBytes     != null ? '✅ Uploaded' : '❌ Missing'),
        _row('Hostel Allocation',
            hostelDocBytes  != null ? '✅ Uploaded' : '❌ Missing'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your application will be reviewed by an admin. '
                      'You will be notified once approved.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _field(
      TextEditingController controller,
      String label, {
        IconData? icon,
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
        bool required = true,
        String? helper,
        String? Function(String?)? extraValidator,
      }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller:   controller,
          obscureText:  obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText:  label,
            helperText: helper,
            prefixIcon: icon != null ? Icon(icon) : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return 'Please enter $label';
            }
            return extraValidator?.call(v);
          },
        ),
      );

  // ✅ No VoidCallback type annotation — uses plain anonymous function
  Widget _imgBtn({
    required String   label,
    required IconData icon,
    required void Function() onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon:  Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

  Widget _hint(String msg) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(msg,
        style: const TextStyle(color: Colors.red, fontSize: 12)),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text('$label:',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // STEPPER LOGIC
  // ══════════════════════════════════════════════════════════════════════════

  void _onStepContinue() {
    if (_validateStep()) setState(() => _currentStep++);
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
      // Trigger visual error messages then check values
        _formKey.currentState?.validate();
        return fNameController.text.trim().isNotEmpty &&
            lNameController.text.trim().isNotEmpty &&
            emailController.text.trim().contains('@') &&
            phoneController.text.trim().isNotEmpty &&
            passwordController.text.length >= 6;

      case 1:
        if (profileBytes == null) {
          _snack('Please upload a profile picture');
          return false;
        }
        return true;

      case 2:
        if (studentIdController.text.trim().isEmpty) {
          _snack('Please enter your student ID number');
          return false;
        }
        if (idCardBytes == null) {
          _snack('Please upload your student ID card photo');
          return false;
        }
        return true;

      case 3:
        if (courseController.text.trim().isEmpty) {
          _snack('Please enter your course of study');
          return false;
        }
        if (selectedYear == null) {
          _snack('Please select your year of study');
          return false;
        }
        return true;

      case 4:
        if (selectedHostel == null) {
          _snack('Please select your hostel');
          return false;
        }
        if (selectedHostelType == null) {
          _snack('Please select hostel type');
          return false;
        }
        if (blockController.text.trim().isEmpty) {
          _snack('Please enter your block number');
          return false;
        }
        if (hostelDocBytes == null) {
          _snack('Please upload your hostel allocation document');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IMAGE PICKER  — XFile + readAsBytes() works on web AND native
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _pickImage(_ImgType type) async {
    final XFile? picked = await _picker.pickImage(
      source:       ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes(); // ✅ works on all platforms

    setState(() {
      switch (type) {
        case _ImgType.profile:
          profileXFile = picked;
          profileBytes = bytes;
          break;
        case _ImgType.idCard:
          idCardXFile = picked;
          idCardBytes = bytes;
          break;
        case _ImgType.hostelDoc:
          hostelDocXFile = picked;
          hostelDocBytes = bytes;
          break;
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUBMIT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    try {
      // 1 ─ Upload all images via bytes (works on web + native)
      final profileUrl = await _cloudinary.uploadImageFromBytes(
        bytes:    profileBytes!,
        fileName: profileXFile!.name,
        folder:   CloudinaryFolders.profilePictures,
      );
      final idCardUrl = await _cloudinary.uploadImageFromBytes(
        bytes:    idCardBytes!,
        fileName: idCardXFile!.name,
        folder:   CloudinaryFolders.idCards,
      );
      final hostelUrl = await _cloudinary.uploadImageFromBytes(
        bytes:    hostelDocBytes!,
        fileName: hostelDocXFile!.name,
        folder:   CloudinaryFolders.hostelAllocations,
      );

      // 2 ─ Firebase Auth
      final cred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email:    emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = cred.user;
      if (user == null) throw Exception('User creation failed');

      await user.updateDisplayName(
          '${fNameController.text.trim()} ${lNameController.text.trim()}');
      await user.reload();

      // 3 ─ Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'firstname':   fNameController.text.trim(),
        'lastname':    lNameController.text.trim(),
        'email':       emailController.text.trim(),
        'role':        'delivery-partner',
        'phoneNumber': phoneController.text.trim(),
        'createdAt':   FieldValue.serverTimestamp(),
        // Verification
        'profileImageUrl': profileUrl,
        'studentId':       studentIdController.text.trim(),
        'idCardImageUrl':  idCardUrl,
        // Academic
        'courseOfStudy': courseController.text.trim(),
        'year':          selectedYear,
        // Hostel
        'hostelName':          selectedHostel,
        'hostelType':          selectedHostelType,
        'blockNumber':         blockController.text.trim(),
        'roomNumber': roomController.text.trim().isEmpty
            ? null
            : roomController.text.trim(),
        'hostelAllocationUrl': hostelUrl,
        // Approval
        'isApproved':     false,
        'approvalStatus': 'pending',
        // Stats
        'isAvailable':       false,
        'currentDeliveries': 0,
        'totalDeliveries':   0,
        'totalEarnings':     0.0,
        'totalRatings':      0,
        'walletBalance':     0.0,
      });

      if (!mounted) return;

      // 4 ─ Success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title:   const Text('Application Submitted! 🎉'),
          content: const Text(
            'Your application has been submitted successfully.\n\n'
                'An admin will review your documents and notify you once approved.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _snack('Signup failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Private enum — no clash with any SDK type
enum _ImgType { profile, idCard, hostelDoc }