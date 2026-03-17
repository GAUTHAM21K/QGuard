// ignore_for_file: prefer_const_constructors, unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatinng/loginpage/kyber_key_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthServices {
  // Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final KyberKeyService _kyberService = KyberKeyService();
  SharedPreferences? _prefs;

  // Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Sign in
  Future<UserCredential> signinwithemailpass(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      if (_prefs == null) await _initPrefs();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user has Kyber keys, generate if missing
      await _ensureUserHasKeys(userCredential.user!.uid);

      // Set user as online
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'is_online': true, 'last_active': Timestamp.now()},
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Ensure user has Kyber keys (for backward compatibility)
  Future<void> _ensureUserHasKeys(String userId) async {
    try {
      // Check if user has public key in Firestore
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      final hasPublicKey =
          data?['publicKey'] != null &&
          (data!['publicKey'] as String).isNotEmpty;

      // Check if user has private key locally
      final privateKey = _prefs!.getString('private_key_$userId');
      final hasPrivateKey = privateKey != null && privateKey.isNotEmpty;

      if (!hasPublicKey || !hasPrivateKey) {
        print('🔧 User missing Kyber keys, generating new key pair...');

        // Generate new key pair
        final keyPair = await _kyberService.generateKeyPair();

        // Store private key locally
        await _prefs!.setString('private_key_$userId', keyPair['privateKey']!);

        // Update public key in Firestore
        await _firestore.collection('users').doc(userId).update({
          'publicKey': keyPair['publicKey'],
        });

        print('✅ Kyber keys generated and stored for existing user');
      } else {
        print('✅ User already has valid Kyber keys');
      }
    } catch (e) {
      print('❌ Error ensuring user has keys: $e');
      // Don't throw here, let the user continue but they might have issues with encryption
    }
  }

  // Update user status
  Future<void> updateUserStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'is_online': isOnline,
        'last_active': Timestamp.now(),
      });
    }
  }

  // Sign up
  Future<UserCredential?> signupwithemailandpass(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      if (_prefs == null) await _initPrefs();

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Generate Kyber key pair for new user
      final keyPair = await _kyberService.generateKeyPair();

      // Store private key in shared preferences
      await _prefs!.setString(
        'private_key_${userCredential.user!.uid}',
        keyPair['privateKey']!,
      );

      // Store public key and user info in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'chattingwith': [],
        'publicKey': keyPair['publicKey'],
        'is_online': true,
        'last_active': Timestamp.now(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign out
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'is_online': false,
        'last_active': Timestamp.now(),
      });
    }
    await _auth.signOut();
  }

  // Check if email exists
  Future<bool> checkEmails(String email) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Add user (optional helper)
  Future<void> addUser(String userId, String email) async {
    await _firestore.collection('users').doc(userId).set({'receiver': email});
  }
}
