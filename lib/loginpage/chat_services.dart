import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatinng/loginpage/message.dart';
import 'package:chatinng/loginpage/kyber_key_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:typed_data';

class ChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final KyberKeyService _kyberService = KyberKeyService();

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  // send - receiverUid must be the recipient's Firestore document id (UID)
  Future<void> sendMessage(String receiverUid, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String? currentUserEmail = _auth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();

    print('🚀 === STARTING SECURE MESSAGE ENCRYPTION PROCESS ===');
    print('📤 Sender: $currentUserEmail ($currentUserId)');
    print('📥 Receiver UID: $receiverUid');
    print('📝 Original message length: ${message.length} characters');
    print('⏰ Timestamp: ${timestamp.toDate()}');

    try {
      // Start timer for the entire process
      final totalStopwatch = Stopwatch()..start();
      final stepStopwatch = Stopwatch()..start();

      print('\n🔐 STEP 1: KYBER KEY EXCHANGE & SESSION KEY GENERATION');
      print('🔍 Fetching recipient\'s Kyber public key from Firestore...');

      // Step 1: Generate and encapsulate AES session key for recipient (use UID)
      final encapsulation = await _kyberService
          .generateAndEncapsulateSessionKey(receiverUid);

      stepStopwatch.stop();
      print(
        "✅ Kyber encapsulation completed in ${stepStopwatch.elapsedMilliseconds}ms",
      );

      final aesKeyB64 = encapsulation['aes_key']!;
      final kyberCiphertextB64 = encapsulation['ciphertext']!;

      print(
        '🔑 Generated AES-256 session key: ${aesKeyB64.substring(0, 16)}...',
      );
      print('📦 Kyber ciphertext length: ${kyberCiphertextB64.length} chars');

      stepStopwatch.reset();
      stepStopwatch.start();

      print('\n🔒 STEP 2: AES-GCM ENCRYPTION SETUP');
      // Step 2: Set up AES-GCM encryption with the session key
      final keyBytes = base64.decode(aesKeyB64);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV.fromSecureRandom(12); // GCM uses 12-byte nonce
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      print('🔧 AES-GCM encrypter initialized');
      print('🎲 Generated IV (nonce): ${base64.encode(iv.bytes)}');
      print('🔐 Key size: ${keyBytes.length * 8} bits');

      print('\n🔐 STEP 3: MESSAGE ENCRYPTION');
      print('📝 Encrypting message with AES-GCM...');

      // Step 3: Encrypt the message using AES-GCM
      final encrypted = encrypter.encrypt(message, iv: iv);

      stepStopwatch.stop();
      print(
        "✅ AES-GCM encryption completed in ${stepStopwatch.elapsedMilliseconds}ms",
      );
      print('🔒 Encrypted message length: ${encrypted.base64.length} chars');
      print(
        '🔒 Encrypted preview: ${encrypted.base64.length > 32 ? encrypted.base64.substring(0, 32) + '...' : encrypted.base64}',
      );

      stepStopwatch.reset();
      stepStopwatch.start();

      print('\n📦 STEP 4: MESSAGE OBJECT CREATION');
      // Step 4: Create message object with encrypted content
      Message newMessage = Message(
        senderID: currentUserId,
        message: encrypted.base64, // Store encrypted message
        receiverID: receiverUid,
        senderEmail: currentUserEmail ?? 'unknown@email.com',
        timestamp: timestamp,
      );

      print('✅ Message object created with encrypted payload');

      print('\n💾 STEP 5: FIRESTORE STORAGE');
      // Step 5: Create chat room ID and store encrypted message with metadata
      // Use UIDs for chatRoom id so sender and receiver compute same id
      List<String> ids = [currentUserId, receiverUid];
      ids.sort();
      String chatRoomID = ids.join('_');

      print('🏠 Chat room ID: $chatRoomID');
      print('💾 Storing encrypted message with metadata to Firestore...');

      await _firestore
          .collection('chatroom')
          .doc(chatRoomID)
          .collection('messages')
          .add({
            ...newMessage.toMap(),
            'encrypted': true,
            'encryption': {
              'algorithm': 'AES-GCM-256',
              'iv': base64.encode(iv.bytes),
              'kyber_ciphertext': kyberCiphertextB64,
            },
          });

      stepStopwatch.stop();
      totalStopwatch.stop();

      print(
        "✅ Firestore storage completed in ${stepStopwatch.elapsedMilliseconds}ms",
      );
      print('\n🎉 === ENCRYPTION PROCESS COMPLETED SUCCESSFULLY ===');
      print("⏱️ Total process time: ${totalStopwatch.elapsedMilliseconds}ms");
      print('🔐 Message secured with post-quantum cryptography');
      print('📡 Ready for secure transmission\n');
    } catch (e) {
      print('\n❌ === ENCRYPTION PROCESS FAILED ===');
      print('💥 Error details: $e');
      print(
        '🔧 Check Kyber library, Firestore connection, and recipient public key',
      );
      rethrow;
    }
  }

  //recieve
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
    return _firestore
        .collection('chatroom')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
