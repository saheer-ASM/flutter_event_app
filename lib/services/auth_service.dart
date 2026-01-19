import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';



class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  User? get currentUser => _auth.currentUser;
  
  // Stream to listen to auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Register with Email & Password
  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String regNumber,
    required String batch,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'regNumber': regNumber,
        'batch': batch,
        'role': 'user',
        'profileImageUrl': null,
        'registeredEvents': [],
      });

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Login with Email & Password
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

 
 // Login with Google
Future<String?> loginWithGoogle() async {
  try {
    // Trigger the sign-in flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return 'Google sign in cancelled';

    // Get authentication tokens
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a credential for Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    // Sign in with Firebase
    UserCredential userCredential =
        await _auth.signInWithCredential(credential);

    // Check if Firestore user exists, else create
    final DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': userCredential.user!.displayName ?? 'User',
        'email': userCredential.user!.email ?? '',
        'regNumber': '',
        'batch': '',
        'role': 'user',
        'profileImageUrl': userCredential.user!.photoURL,
        'registeredEvents': [],
      });
    }

    return null; // Success
  } catch (e) {
    return 'Google sign in failed: $e';
  }
}



  // Reset Password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Change Password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = currentUser;
      if (user == null) return 'No user logged in';

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to change password';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }
}