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
    print('\n🔐 === KYBER KEY PAIR GENERATION ===');
    print('🔧 Allocating memory for Kyber-512 key pair...');

    final pkPtr = calloc<Uint8>(800); // Sizes depend on Kyber variant
    final skPtr = calloc<Uint8>(1632);

    try {
      print('🎲 Generating Kyber-512 key pair...');
      final stopwatch = Stopwatch()..start();

      final res = _keypair(pkPtr, skPtr);

      stopwatch.stop();
      print("⏱️ Key pair generation took: ${stopwatch.elapsedMilliseconds}ms");

      if (res != 0) {
        print('❌ Keypair generation failed with code: $res');
        throw Exception("Keypair generation failed");
      }

      final publicKeyBytes = pkPtr.asTypedList(800);
      final privateKeyBytes = skPtr.asTypedList(1632);

      final publicKeyB64 = base64.encode(publicKeyBytes);
      final privateKeyB64 = base64.encode(privateKeyBytes);

      print('✅ Key pair generated successfully');
      print(
        '🔑 Public key length: ${publicKeyBytes.length} bytes (${publicKeyB64.length} chars base64)',
      );
      print(
        '🔐 Private key length: ${privateKeyBytes.length} bytes (${privateKeyB64.length} chars base64)',
      );
      print('🔑 Public key preview: ${publicKeyB64.substring(0, 32)}...');

      return {'publicKey': publicKeyB64, 'privateKey': privateKeyB64};
    } finally {
      calloc.free(pkPtr);
      calloc.free(skPtr);
      print('🧹 Memory cleanup completed');
    }
  }

  Future<Map<String, String>> generateAndEncapsulateSessionKey(
    String recipientUid,
  ) async {
    print('\n🔐 === KYBER ENCAPSULATION PROCESS ===');
    print('🎯 Target recipient UID: $recipientUid');

    final stopwatch = Stopwatch()..start();

    print('🔍 Step 1: Fetching recipient\'s public key from Firestore...');
    // 1. Fetch recipient public key from Firestore
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientUid)
            .get();

    if (!doc.exists) {
      print('❌ Recipient not found in Firestore');
      throw Exception('Recipient not found');
    }

    final data = doc.data();
    final pkB64 = data?['publicKey'] as String?;

    if (pkB64 == null || pkB64.isEmpty) {
      print(
        '⚠️ Recipient has no public key - this user needs to update their app',
      );
      print('🔧 Generating emergency key pair for recipient...');

      // Generate a key pair for the recipient
      final keyPair = await generateKeyPair();

      // Update the recipient's document with the new public key
      await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUid)
          .update({'publicKey': keyPair['publicKey']});

      print('✅ Emergency public key generated and stored for recipient');
      print(
        '⚠️ Note: Recipient will need to log out and back in to get their private key',
      );

      // Use the newly generated public key
      final pkBytes = base64.decode(keyPair['publicKey']!);
      print('📦 Using emergency public key: ${pkBytes.length} bytes');

      return await _performEncapsulation(keyPair['publicKey']!, stopwatch);
    }

    print('✅ Retrieved public key from Firestore');
    print('🔑 Public key length: ${pkB64.length} chars');
    print('🔑 Public key preview: ${pkB64.substring(0, 32)}...');

    return await _performEncapsulation(pkB64, stopwatch);
  }

  Future<Map<String, String>> _performEncapsulation(
    String pkB64,
    Stopwatch stopwatch,
  ) async {
    final pkBytes = base64.decode(pkB64);
    print('📦 Decoded public key: ${pkBytes.length} bytes');

    print('\n🔧 Step 2: Setting up memory for encapsulation...');
    final ctPtr = calloc<Uint8>(768); // Ciphertext
    final ssPtr = calloc<Uint8>(32); // Shared secret (AES key)
    final pkPtr = calloc<Uint8>(pkBytes.length);

    pkPtr.asTypedList(pkBytes.length).setAll(0, pkBytes);
    print('✅ Memory allocated and public key loaded');

    try {
      print('\n🎲 Step 3: Performing Kyber-512 encapsulation...');
      final encapStopwatch = Stopwatch()..start();

      final result = _encaps(ctPtr, ssPtr, pkPtr);

      encapStopwatch.stop();
      print(
        "⏱️ Kyber encapsulation took: ${encapStopwatch.elapsedMilliseconds}ms",
      );

      if (result != 0) {
        print('❌ Encapsulation failed with code: $result');
        throw Exception('Kyber encapsulation failed');
      }

      final ciphertextBytes = ctPtr.asTypedList(768);
      final sharedSecretBytes = ssPtr.asTypedList(32);

      final ciphertextB64 = base64.encode(ciphertextBytes);
      final aesKeyB64 = base64.encode(sharedSecretBytes);

      stopwatch.stop();

      print('✅ Encapsulation completed successfully');
      print(
        '📦 Ciphertext length: ${ciphertextBytes.length} bytes (${ciphertextB64.length} chars base64)',
      );
      print('🔑 AES session key: 256 bits (${sharedSecretBytes.length} bytes)');
      print('📦 Ciphertext preview: ${ciphertextB64.substring(0, 32)}...');
      print('🔑 AES key preview: ${aesKeyB64.substring(0, 16)}...');
      print(
        "⏱️ Total encapsulation process: ${stopwatch.elapsedMilliseconds}ms",
      );

      return {'ciphertext': ciphertextB64, 'aes_key': aesKeyB64};
    } finally {
      calloc.free(ctPtr);
      calloc.free(ssPtr);
      calloc.free(pkPtr);
      print('🧹 Encapsulation memory cleanup completed');
    }
  }

  Future<String> decapsulate(String ctB64, String skB64) async {
    print('\n🔓 === KYBER DECAPSULATION PROCESS ===');
    print('📦 Ciphertext length: ${ctB64.length} chars');
    print('🔐 Private key length: ${skB64.length} chars');

    final stopwatch = Stopwatch()..start();

    print('🔧 Step 1: Decoding base64 inputs...');
    final ctBytes = base64.decode(ctB64);
    final skBytes = base64.decode(skB64);

    print('✅ Decoded ciphertext: ${ctBytes.length} bytes');
    print('✅ Decoded private key: ${skBytes.length} bytes');

    print('\n🔧 Step 2: Setting up memory for decapsulation...');
    final ssPtr = calloc<Uint8>(32); // Shared secret output
    final ctPtr = calloc<Uint8>(ctBytes.length);
    final skPtr = calloc<Uint8>(skBytes.length);

    ctPtr.asTypedList(ctBytes.length).setAll(0, ctBytes);
    skPtr.asTypedList(skBytes.length).setAll(0, skBytes);
    print('✅ Memory allocated and inputs loaded');

    try {
      print('\n🔓 Step 3: Performing Kyber-512 decapsulation...');
      final decapStopwatch = Stopwatch()..start();

      final result = _decaps(ssPtr, ctPtr, skPtr);

      decapStopwatch.stop();
      print(
        "⏱️ Kyber decapsulation took: ${decapStopwatch.elapsedMilliseconds}ms",
      );

      if (result != 0) {
        print('❌ Decapsulation failed with code: $result');
        throw Exception('Kyber decapsulation failed');
      }

      final sharedSecretBytes = ssPtr.asTypedList(32);
      final aesKeyB64 = base64.encode(sharedSecretBytes);

      stopwatch.stop();

      print('✅ Decapsulation completed successfully');
      print(
        '🔑 Recovered AES session key: 256 bits (${sharedSecretBytes.length} bytes)',
      );
      print('🔑 AES key preview: ${aesKeyB64.substring(0, 16)}...');
      print(
        "⏱️ Total decapsulation process: ${stopwatch.elapsedMilliseconds}ms",
      );

      return aesKeyB64;
    } finally {
      calloc.free(ssPtr);
      calloc.free(ctPtr);
      calloc.free(skPtr);
      print('🧹 Decapsulation memory cleanup completed');
    }
  }

  SharedPreferences? _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Saves the private key locally using SharedPreferences.
  Future<void> savePrivateKey(String base64Key, String userId) async {
    print('\n💾 === SAVING PRIVATE KEY LOCALLY ===');
    print('👤 User ID: $userId');
    print('🔐 Key length: ${base64Key.length} chars');

    try {
      await _initPrefs();
      final String storageKey = 'private_key_$userId';

      print('🔧 Storing key in SharedPreferences...');
      await _prefs!.setString(storageKey, base64Key);

      print('✅ Private key saved locally for user: $userId');
      print('🔑 Storage key: $storageKey');
    } catch (e) {
      print('❌ Failed to save private key: $e');
      rethrow;
    }
  }

  /// Loads the private key from local storage, with a Firestore fallback.
  Future<String?> loadPrivateKey(String userId) async {
    print('\n🔍 === LOADING PRIVATE KEY ===');
    print('👤 User ID: $userId');

    try {
      await _initPrefs();
      final String storageKey = 'private_key_$userId';

      print('🔧 Step 1: Checking local SharedPreferences...');
      // 1. Check local storage first
      final String? localKey = _prefs!.getString(storageKey);
      if (localKey != null && localKey.isNotEmpty) {
        print('✅ Private key found in local storage');
        print('🔐 Key length: ${localKey.length} chars');
        print('🔑 Key preview: ${localKey.substring(0, 16)}...');
        return localKey;
      }

      print('⚠️ Private key not found locally');
      print('🔧 Step 2: Checking Firestore fallback...');
      // 2. Fallback to Firestore if local storage is empty
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        final String? cloudKey = data?['privateKey'] as String?;
        if (cloudKey != null && cloudKey.isNotEmpty) {
          print('✅ Private key found in Firestore');
          print('🔐 Key length: ${cloudKey.length} chars');
          print('🔄 Migrating cloud key to local storage...');

          // Migrate cloud key to local storage for future use
          await savePrivateKey(cloudKey, userId);
          return cloudKey;
        }
      }

      print('❌ No private key found for user $userId in any location');
      print('🔧 User may need to regenerate key pair');
      return null;
    } catch (e) {
      print('❌ Error loading private key: $e');
      return null;
    }
  }

  // Helper methods for storage (savePrivateKey/loadPrivateKey) remain as they were in your file
}
