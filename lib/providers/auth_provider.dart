import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final loginFail = StateProvider<String?>((ref) => null);
final isLogin = StateProvider<bool?>((ref) => null);
final signUpFail = StateProvider<String?>((ref) => null);
final role = StateProvider<String?>((ref) => null);
final displayName = StateProvider<String?>((ref) => null);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

Future<bool> emailExistsInFirestore(String email) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .get();

  return snapshot.docs.isNotEmpty;
}

Future<void> addUser(
  WidgetRef ref,
  String email,
  String password,
  String fName,
  String lName,
  String phoneNumber,
  String userRole,
) async {
  try {
    // Create user in Firebase Auth
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;


    if (user == null) {
      ref.read(signUpFail.notifier).state = "User creation failed";
      throw Exception("User creation failed — no user returned.");
    }

    // Update display name
    await user.updateDisplayName("$fName $lName");
    await user.reload();

    // Update state
    ref.read(displayName.notifier).state = "$fName $lName";
    ref.read(role.notifier).state = userRole;

    print("Display Name: ${ref.read(displayName)}");

    // Write basic user data to Firestore (for customers only)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'firstname': fName,
      'lastname': lName,
      'email': email,
      'role': userRole,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("$userRole document created for UID: ${user.uid}");

    // Clear any previous error
    ref.read(signUpFail.notifier).state = null;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      ref.read(signUpFail.notifier).state =
          'The password provided is too weak.';
    } else if (e.code == 'email-already-in-use') {
      ref.read(signUpFail.notifier).state =
          'The account already exists for that email.';
    } else {
      ref.read(signUpFail.notifier).state = 'Auth error: ${e.message}';
    }
    rethrow;
  } catch (e) {
    ref.read(signUpFail.notifier).state = 'Unexpected error: $e';
    print("Error adding user: $e");
    rethrow;
  }
}

Future<void> loginUser(WidgetRef ref, String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    if (userCredential.user?.uid != null) {
      // Fetch user role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.exists) {
        ref.read(role.notifier).state = userDoc['role'];
        ref.read(displayName.notifier).state = userCredential.user?.displayName;
        ref.read(isLogin.notifier).state = true;

        print("User logged in: ${userDoc.data()}");
      } else {
        ref.read(loginFail.notifier).state = 'User profile not found';
        throw Exception('User profile not found in Firestore');
      }
      
      // Clear any previous error
      ref.read(loginFail.notifier).state = null;
      
    } else {
      ref.read(isLogin.notifier).state = false;
      ref.read(loginFail.notifier).state = 'Login failed';
      throw Exception('Login failed: No user returned');
    }
  } on FirebaseAuthException catch (e) {
    ref.read(isLogin.notifier).state = false;
    if (e.code == 'user-not-found') {
      ref.read(loginFail.notifier).state = 'No user found for that email.';
    } else if (e.code == 'wrong-password') {
      ref.read(loginFail.notifier).state = 'Wrong password provided.';
    } else if (e.code == 'invalid-email') {
      ref.read(loginFail.notifier).state = 'Invalid email address.';
    } else {
      ref.read(loginFail.notifier).state = 'Login error: ${e.message}';
    }
    rethrow;
  } catch (e) {
    ref.read(isLogin.notifier).state = false;
    ref.read(loginFail.notifier).state = 'Unexpected error: $e';
    print("Error logging in: $e");
    rethrow;
  }
}

// Password reset function
Future<void> resetPassword(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      throw Exception('No user found for that email.');
    } else {
      throw Exception('Error: ${e.message}');
    }
  }
}
