import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KyberKeyService {
  static final KyberKeyService _instance = KyberKeyService._internal();
  final String serverIp = '10.20.77.118'; // Your Flask server IP
  SharedPreferences? _prefs;

  factory KyberKeyService() {
    return _instance;
  }

  KyberKeyService._internal() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const int kyberSymBytes = 32;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _secureRandom = Random.secure();

  Future<void> savePrivateKey(String base64Key, String userId) async {
    try {
      if (_prefs == null) await _initPrefs();
      
      // Use a consistent key for each user's private key
      final String storageKey = 'private_key_$userId';
      
      // Write the base64 encoded key to shared preferences
      await _prefs!.setString(storageKey, base64Key);
      
      print('✅ Private key saved for user: $userId');
    } catch (e) {
      print('❌ Failed to save private key: $e');
      rethrow;
    }
  }

  Future<String?> loadPrivateKey(String userId) async {
    try {
      if (_prefs == null) await _initPrefs();
      
      final String storageKey = 'private_key_$userId';
      
      // Read the key from shared preferences
      final String? base64Key = _prefs!.getString(storageKey);

      if (base64Key != null && base64Key.isNotEmpty) {
        print('✅ Private key loaded for user $userId');
        return base64Key;
      }

      // If not found in shared preferences, attempt the Firestore fallback
      print('⚠️ No private key found in storage for user $userId - trying Firestore fallback');
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data();
          final String? privateKeyField = data != null ? (data['privateKey'] as String?) : null;
          if (privateKeyField != null && privateKeyField.isNotEmpty) {
            print('⚠️ Private key loaded from Firestore for user $userId - migrating to local storage');
            // Save the key from Firestore to shared preferences for future use
            await savePrivateKey(privateKeyField, userId);
            return privateKeyField;
          }
        }
      } catch (e) {
        print('⚠️ Failed to read privateKey from Firestore fallback: $e');
      }

      print('⚠️ No private key found for user $userId in any location.');
      return null;

    } catch (e) {
      print('❌ Failed to load private key: $e');
      return null;
    }
  }

  //
  // --- NO CHANGES NEEDED FOR THE METHODS BELOW ---
  //

  Future<Map<String, String>> generateKeyPair() async {
    final String apiUrl = 'http://$serverIp:5000/generate_keys';
    
    try {
      print('📡 Connecting to Kyber key generation server...');
      print('🔗 URL: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: { 'Accept': 'application/json', 'Content-Type': 'application/json', },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () { throw TimeoutException('Request timed out after 10 seconds'); },
      );
      
      print('📥 Response received. Status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          final String publicKey = data['public_key'];
          final String secretKey = data['secret_key'];
          print('✅ Successfully received keys!');
          return { 'publicKey': publicKey, 'privateKey': secretKey, };
        } else {
          final errorMessage = data['message'] ?? 'Unknown API error';
          print('❌ API returned an error: $errorMessage');
          throw Exception('API Error: $errorMessage');
        }
      } else {
        print('\n❌ Failed to connect to the server');
        print('Status code: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ An error occurred while making the request: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<String> decapsulate(String ciphertextB64, String privateKeyB64, {int kyberMode = 512}) async {
    final String apiUrl = 'http://$serverIp:5000/decapsulate';

    try {
      final Map<String, dynamic> payload = {
        'ciphertext': ciphertextB64,
        'private_key': privateKeyB64,
        'kyber_mode': kyberMode,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: { 'Accept': 'application/json', 'Content-Type': 'application/json', },
        body: json.encode(payload),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out after 10 seconds'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> resp = json.decode(response.body);
        if (resp['status'] == 'success') {
          return resp['aes_key'];
        } else {
          final err = resp['message'] ?? 'Unknown error from API';
          throw Exception('API error: $err');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to decapsulate session key: $e');
    }
  }

  Future<Map<String, String>> generateAndEncapsulateSessionKey(String recipientUid, {int kyberMode = 512}) async {
    final String apiUrl = 'http://$serverIp:5000/encapsulate';

    try {
      final doc = await _firestore.collection('users').doc(recipientUid).get();
      if (!doc.exists) {
        throw Exception('Recipient user not found in Firestore: $recipientUid');
      }

      final data = doc.data();
      final String? recipientPkB64 = data != null ? (data['publicKey'] as String?) : null;
      if (recipientPkB64 == null || recipientPkB64.isEmpty) {
        throw Exception('Recipient publicKey missing for user $recipientUid');
      }

      final Uint8List aesKeyBytes = _generateRandomBytes(kyberSymBytes);
      final String aesKeyB64 = base64.encode(aesKeyBytes);

      final Map<String, dynamic> payload = {
        'aes_key': aesKeyB64,
        'recipient_pk': recipientPkB64,
        'kyber_mode': kyberMode,
      };

      final response = await http
          .post(Uri.parse(apiUrl), headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }, body: json.encode(payload)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out after 10 seconds'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> resp = json.decode(response.body);
        if (resp['status'] == 'success') {
          return {
            'ciphertext': resp['ciphertext'],
            'aes_key': aesKeyB64,
          };
        } else {
          final err = resp['message'] ?? 'Unknown error from API';
          throw Exception('API error: $err');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to encapsulate session key: $e');
    }
  }

  Uint8List _generateRandomBytes(int length) {
    final List<int> bytes = List<int>.generate(length, (_) => _secureRandom.nextInt(256));
    return Uint8List.fromList(bytes);
  }
}