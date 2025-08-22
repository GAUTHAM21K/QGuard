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


  Stream<List<Map<String,dynamic>>>getUsersStream(){
      return _firestore.collection("users").snapshots().map((Snapshot) {
        return Snapshot.docs.map((doc){
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

    try {
  // Step 1: Generate and encapsulate AES session key for recipient (use UID)
  final encapsulation = await _kyberService.generateAndEncapsulateSessionKey(receiverUid);
  final aesKeyB64 = encapsulation['aes_key']!;
  final kyberCiphertextB64 = encapsulation['ciphertext']!;

      // Step 2: Set up AES-GCM encryption with the session key
      final keyBytes = base64.decode(aesKeyB64);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV.fromSecureRandom(12); // GCM uses 12-byte nonce
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

      // Step 3: Encrypt the message using AES-GCM
      final encrypted = encrypter.encrypt(message, iv: iv);

      // Step 4: Create message object with encrypted content
      Message newMessage = Message(
        senderID: currentUserId,
        message: encrypted.base64, // Store encrypted message
        receiverID: receiverUid,
        senderEmail: currentUserEmail.toString(),
        timestamp: timestamp);

      // Step 5: Create chat room ID and store encrypted message with metadata
  // Use UIDs for chatRoom id so sender and receiver compute same id
  List<String> ids = [currentUserId, receiverUid];
      ids.sort();
      String chatRoomID = ids.join('_');

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
          }
        });

      print('✅ Message encrypted and sent successfully');
    } catch (e) {
      print('❌ Failed to encrypt or send message: $e');
      rethrow;
    }
  }


  


  //recieve
  Stream<QuerySnapshot> getMessages(String userID, otherUserID){
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
    return _firestore.collection('chatroom').doc(chatRoomID).collection('messages').orderBy('timestamp',descending: false).snapshots();
  }

}