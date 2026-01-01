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
      BuildContext context, String email, String password) async {
    try {
      if (_prefs == null) await _initPrefs();
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Fetch private key from shared preferences
      final privateKey = _prefs!.getString('private_key_${userCredential.user!.uid}');

      if (privateKey == null) {
        // If private key missing, throw an error
        throw Exception(
            "Private key not found. Please login again or contact support.");
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign up
  Future<UserCredential?> signupwithemailandpass(
      BuildContext context, String email, String password) async {
    try {
      if (_prefs == null) await _initPrefs();
      
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
              email: email, password: password);

      // Generate Kyber key pair for new user
      final keyPair = await _kyberService.generateKeyPair();

      // Store private key in shared preferences
      await _prefs!.setString(
          'private_key_${userCredential.user!.uid}', keyPair['privateKey']!);

      // Store public key and user info in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'chattingwith': [],
        'publicKey': keyPair['publicKey'],
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if email exists
  Future<bool> checkEmails(String email) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('users').where('email', isEqualTo: email).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Add user (optional helper)
  Future<void> addUser(String userId, String email) async {
    await _firestore.collection('users').doc(userId).set({
      'receiver': email,
    });
  }
}