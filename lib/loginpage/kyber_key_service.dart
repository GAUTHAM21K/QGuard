import 'dart:ffi';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// FFI Signatures
typedef KyberFunc = Int32 Function(Pointer<Uint8>, Pointer<Uint8>);
typedef KyberFuncDart = int Function(Pointer<Uint8>, Pointer<Uint8>);

typedef KyberEncaps =
    Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>);
typedef KyberEncapsDart =
    int Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>);

class KyberKeyService {
  late DynamicLibrary _lib;
  late KyberFuncDart _keypair;
  late KyberEncapsDart _encaps;
  late KyberEncapsDart _decaps;

  KyberKeyService() {
    _loadLibrary();
  }

  void _loadLibrary() {
    try {
      _lib =
          Platform.isAndroid
              ? DynamicLibrary.open("libkyber.so")
              : DynamicLibrary.process();

      _keypair = _lib.lookupFunction<KyberFunc, KyberFuncDart>(
        "kyber512_keypair",
      );
      _encaps = _lib.lookupFunction<KyberEncaps, KyberEncapsDart>(
        "kyber512_encaps",
      );
      _decaps = _lib.lookupFunction<KyberEncaps, KyberEncapsDart>(
        "kyber512_decaps",
      );
    } catch (e) {
      print('❌ Failed to load Kyber library: $e');
      print('Make sure libkyber.so is built for your platform architecture');
      rethrow;
    }
  }

  Future<Map<String, String>> generateKeyPair() async {
    final pkPtr = calloc<Uint8>(800); // Sizes depend on Kyber variant
    final skPtr = calloc<Uint8>(1632);

    try {
      final res = _keypair(pkPtr, skPtr);
      if (res != 0) throw Exception("Keypair generation failed");

      return {
        'publicKey': base64.encode(pkPtr.asTypedList(800)),
        'privateKey': base64.encode(skPtr.asTypedList(1632)),
      };
    } finally {
      calloc.free(pkPtr);
      calloc.free(skPtr);
    }
  }

  Future<Map<String, String>> generateAndEncapsulateSessionKey(
    String recipientUid,
  ) async {
    // 1. Fetch recipient public key from Firestore
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientUid)
            .get();
    final pkB64 = doc.data()?['publicKey'];
    final pkBytes = base64.decode(pkB64);

    final ctPtr = calloc<Uint8>(768);
    final ssPtr = calloc<Uint8>(32);
    final pkPtr = calloc<Uint8>(pkBytes.length);

    pkPtr.asTypedList(pkBytes.length).setAll(0, pkBytes);

    try {
      _encaps(ctPtr, ssPtr, pkPtr);
      return {
        'ciphertext': base64.encode(ctPtr.asTypedList(768)),
        'aes_key': base64.encode(ssPtr.asTypedList(32)),
      };
    } finally {
      calloc.free(ctPtr);
      calloc.free(ssPtr);
      calloc.free(pkPtr);
    }
  }

  Future<String> decapsulate(String ctB64, String skB64) async {
    final ctBytes = base64.decode(ctB64);
    final skBytes = base64.decode(skB64);

    final ssPtr = calloc<Uint8>(32);
    final ctPtr = calloc<Uint8>(ctBytes.length);
    final skPtr = calloc<Uint8>(skBytes.length);

    ctPtr.asTypedList(ctBytes.length).setAll(0, ctBytes);
    skPtr.asTypedList(skBytes.length).setAll(0, skBytes);

    try {
      _decaps(ssPtr, ctPtr, skPtr);
      return base64.encode(ssPtr.asTypedList(32));
    } finally {
      calloc.free(ssPtr);
      calloc.free(ctPtr);
      calloc.free(skPtr);
    }
  }

  SharedPreferences? _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Saves the private key locally using SharedPreferences.
  Future<void> savePrivateKey(String base64Key, String userId) async {
    try {
      await _initPrefs();
      final String storageKey = 'private_key_$userId';
      await _prefs!.setString(storageKey, base64Key);
      print('✅ Private key saved locally for user: $userId');
    } catch (e) {
      print('❌ Failed to save private key: $e');
      rethrow;
    }
  }

  /// Loads the private key from local storage, with a Firestore fallback.
  Future<String?> loadPrivateKey(String userId) async {
    try {
      await _initPrefs();
      final String storageKey = 'private_key_$userId';

      // 1. Check local storage first
      final String? localKey = _prefs!.getString(storageKey);
      if (localKey != null && localKey.isNotEmpty) {
        print('✅ Private key loaded from local storage');
        return localKey;
      }

      // 2. Fallback to Firestore if local storage is empty
      print('⚠️ Private key not found locally, checking Firestore fallback...');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        final String? cloudKey = data?['privateKey'];
        if (cloudKey != null && cloudKey.isNotEmpty) {
          // Migrate cloud key to local storage for future use
          await savePrivateKey(cloudKey, userId);
          return cloudKey;
        }
      }

      print('❌ No private key found for user $userId in any location.');
      return null;
    } catch (e) {
      print('❌ Error loading private key: $e');
      return null;
    }
  }

  // Helper methods for storage (savePrivateKey/loadPrivateKey) remain as they were in your file
}
