// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatinng/loginpage/chat_services.dart';
import 'package:chatinng/loginpage/kyber_key_service.dart';
import 'package:chatinng/loginpage/background_widget.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:typed_data';


import 'package:shared_preferences/shared_preferences.dart';

class chatpage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  chatpage({super.key, required this.receiverEmail, required this.receiverID});

  @override
  State<chatpage> createState() => _chatpageState();
}

class _chatpageState extends State<chatpage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final KyberKeyService _kyberService = KyberKeyService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, String> _decryptedCache = {};
  
  SharedPreferences? _prefs;
  List<Map<String, dynamic>> _locallySentMessages = [];
  bool _isLoading = true; // To show a loader while messages are read from storage

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    // Initialize SharedPreferences and load messages
    _initPrefs().then((_) => _loadLocalMessages());
  }
  
  // ✨ 3. NEW: GET A UNIQUE ID FOR THE CHAT ROOM STORAGE
  String _getChatRoomId() {
    List<String> ids = [_auth.currentUser!.uid, widget.receiverID];
    ids.sort(); // Sort the ids to ensure the chatRoomID is always the same for any 2 people
    return ids.join('_');
  }

  // Load messages from shared preferences
  Future<void> _loadLocalMessages() async {
    try {
      if (_prefs == null) await _initPrefs();
      
      final chatRoomId = _getChatRoomId();
      final messagesJson = _prefs!.getString(chatRoomId);
      if (messagesJson != null) {
        // Decode the JSON string back into a List
        final List<dynamic> decodedList = jsonDecode(messagesJson);
        setState(() {
          _locallySentMessages = List<Map<String, dynamic>>.from(decodedList);
        });
      }
    } catch (e) {
      print("Error loading messages from storage: $e");
    } finally {
      setState(() {
        _isLoading = false; // Stop the loading indicator
      });
    }
  }

  // Save messages to shared preferences
  Future<void> _saveLocalMessages() async {
    try {
      if (_prefs == null) await _initPrefs();
      
      final chatRoomId = _getChatRoomId();
      // Encode the list of messages into a JSON string
      final messagesJson = jsonEncode(_locallySentMessages);
      await _prefs!.setString(chatRoomId, messagesJson);
    } catch (e) {
      print("Error saving messages to storage: $e");
    }
  }

  // Decrypts incoming messages
  Future<String> _decryptMessage(DocumentSnapshot doc) async {
    // ... (This function remains unchanged)
    final String docId = doc.id;
    if (_decryptedCache.containsKey(docId)) return _decryptedCache[docId]!;
    try {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (!(data['encrypted'] == true)) return data['message'] as String? ?? '';
      final encMeta = data['encryption'] as Map<String, dynamic>?;
      final String? kyberCiphertextB64 = encMeta != null ? encMeta['kyber_ciphertext'] as String? : null;
      final String? ivB64 = encMeta != null ? encMeta['iv'] as String? : null;
      if (kyberCiphertextB64 == null || ivB64 == null) return data['message'] as String? ?? '';
      final String currentUid = _auth.currentUser!.uid;
      final String? privateKeyB64 = await _kyberService.loadPrivateKey(currentUid);
      if (privateKeyB64 == null) throw Exception('private key missing');
      final String aesKeyB64 = await _kyberService.decapsulate(kyberCiphertextB64, privateKeyB64);
      final keyBytes = base64.decode(aesKeyB64);
      final String cipherB64 = data['message'] as String;
      final List<int> cipherBytes = base64.decode(cipherB64);
      final List<int> ivBytes = base64.decode(ivB64);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final decrypted = encrypter.decrypt(encrypt.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
      _decryptedCache[docId] = decrypted;
      return decrypted;
    } catch (e, st) {
      print('❌ Decryption failed for doc ${doc.id}: $e\n$st');
      throw e;
    }
  }

  // ✨ 6. UPDATED: sendMessage NOW SAVES THE MESSAGES
  void sendMessage() async {
    if (_textEditingController.text.isNotEmpty) {
      String messageText = _textEditingController.text;

      final messageData = {
        "text": messageText,
        // Use millisecondsSinceEpoch for JSON compatibility
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      // Add the message to our local list for immediate display
      setState(() {
        _locallySentMessages.add(messageData);
      });
      _textEditingController.clear();
      
      // Save the updated list to secure storage
      await _saveLocalMessages();

      // Send the encrypted message to the database in the background
      await _chatServices.sendMessage(widget.receiverID, messageText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[300]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
                         // Profile icon
             Container(
               width: 40,
               height: 40,
               decoration: BoxDecoration(
                 color: Colors.grey[400],
                 shape: BoxShape.circle,
               ),
               child: Center(
                 child: Text(
                   widget.receiverEmail.isNotEmpty ? widget.receiverEmail[0].toUpperCase() : 'U',
                   style: TextStyle(
                     color: Color(0xFF1A1A1A),
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
             ),
            SizedBox(width: 12),
            // Name and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                 Text(
                   widget.receiverEmail,
                   style: TextStyle(
                     color: Colors.grey[300],
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                                         Text(
                       'Online',
                       style: TextStyle(
                         color: Colors.grey[300]!.withOpacity(0.7),
                         fontSize: 12,
                       ),
                     ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
             body: BackgroundWidget(
         child: Column(
           children: [
             // Show a loader while loading, otherwise show the chat list
             Expanded(child: _isLoading ? Center(child: CircularProgressIndicator(color: Colors.grey[300])) : _buildMessageList()),
             _userInput(),
           ],
         ),
       ),
    );
  }

  // ✨ 7. UPDATED: _buildMessageList HANDLES THE NEW TIMESTAMP FORMAT
  Widget _buildMessageList() {
    String currentUserID = _auth.currentUser!.uid;
    return StreamBuilder(
      stream: _chatServices.getMessages(widget.receiverID, currentUserID),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("error");
        // No need for a loading indicator here, the main build method has one
        
        List<Map<String, dynamic>> combinedMessages = [];
        
        // Add received messages from Firestore
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (data['senderID'] != currentUserID) {
              combinedMessages.add({
                "source": "firestore",
                "data": doc,
                "timestamp": data['timestamp'], // This is a Firestore Timestamp object
              });
            }
          }
        }
        
        // Add locally sent messages
        for (var msg in _locallySentMessages) {
          combinedMessages.add({
            "source": "local",
            "text": msg['text'],
            // Convert the integer timestamp from storage back to a Timestamp object for sorting
            "timestamp": Timestamp.fromMillisecondsSinceEpoch(msg['timestamp']),
          });
        }
        
        // Sort all messages by timestamp
        combinedMessages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
        
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: combinedMessages.length,
          itemBuilder: (context, index) {
            final message = combinedMessages[index];
            if (message['source'] == 'firestore') {
              return buildMessageItem(message['data']);
            } else {
              return _buildSentMessageItem(message['text']);
            }
          },
        );
      },
    );
  }
  
  // Updated message item widget with new styling
  Widget buildMessageItem(DocumentSnapshot doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                     // Profile icon for received messages
           Container(
             width: 32,
             height: 32,
             decoration: BoxDecoration(
               color: Colors.grey[400],
               shape: BoxShape.circle,
             ),
             child: Center(
               child: Text(
                 widget.receiverEmail.isNotEmpty ? widget.receiverEmail[0].toUpperCase() : 'U',
                 style: TextStyle(
                   color: Color(0xFF1A1A1A),
                   fontSize: 14,
                   fontWeight: FontWeight.bold,
                 ),
               ),
             ),
           ),
          SizedBox(width: 8),
          // Message bubble
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                                     decoration: BoxDecoration(
                     borderRadius: BorderRadius.only(
                       topLeft: Radius.circular(4),
                       topRight: Radius.circular(16),
                       bottomLeft: Radius.circular(16),
                       bottomRight: Radius.circular(16),
                     ),
                     color: Colors.grey[300]!.withOpacity(0.05),
                     border: Border.all(
                       color: Colors.grey[300]!.withOpacity(0.2),
                       width: 1,
                     ),
                   ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: FutureBuilder<String>(
                    future: _decryptMessage(doc),
                    builder: (context, snap) {
                                             return Text(
                         snap.data ?? "...",
                         style: TextStyle(
                           color: Colors.grey[300],
                           fontSize: 14,
                         ),
                       );
                    },
                  ),
                ),
                SizedBox(height: 4),
                                 Text(
                   _formatTime((doc.data() as Map<String, dynamic>?)?['timestamp']),
                   style: TextStyle(
                     color: Colors.grey[300]!.withOpacity(0.6),
                     fontSize: 11,
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated sent message item widget with new styling
  Widget _buildSentMessageItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message bubble
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                                     decoration: BoxDecoration(
                     borderRadius: BorderRadius.only(
                       topLeft: Radius.circular(16),
                       topRight: Radius.circular(4),
                       bottomLeft: Radius.circular(16),
                       bottomRight: Radius.circular(16),
                     ),
                     color: Colors.grey[300]!.withOpacity(0.1),
                     border: Border.all(
                       color: Colors.grey[300]!.withOpacity(0.3),
                       width: 1,
                     ),
                   ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                     child: Text(
                     text,
                     style: TextStyle(
                       color: Colors.grey[300],
                       fontSize: 14,
                     ),
                   ),
                ),
                SizedBox(height: 4),
                                 Text(
                   _formatTime(DateTime.now()),
                   style: TextStyle(
                     color: Colors.grey[300]!.withOpacity(0.6),
                     fontSize: 11,
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to format time
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }
    
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  // Updated user input widget with new styling
  Widget _userInput() {
    return Container(
      padding: EdgeInsets.all(16),
             decoration: BoxDecoration(
         color: Color(0xFF1A1A1A),
         border: Border(
           top: BorderSide(
             color: Colors.grey[300]!.withOpacity(0.2),
             width: 1,
           ),
         ),
       ),
      child: Row(
        children: [
          Expanded(
            child: Container(
                             decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(25),
                 border: Border.all(
                   color: Colors.grey[300]!.withOpacity(0.3),
                   width: 1,
                 ),
                 color: Colors.grey[300]!.withOpacity(0.05),
               ),
               child: TextField(
                 controller: _textEditingController,
                 style: TextStyle(
                   color: Colors.grey[300],
                   fontSize: 14,
                 ),
                 decoration: InputDecoration(
                   hintText: 'Message',
                   hintStyle: TextStyle(
                     color: Colors.grey[300]!.withOpacity(0.5),
                   ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
                     Container(
             decoration: BoxDecoration(
               color: Colors.grey[400],
               shape: BoxShape.circle,
             ),
            child: IconButton(
              onPressed: sendMessage,
              icon: Icon(
                Icons.send,
                color: Color(0xFF1A1A1A),
                size: 20,
              ),
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
            ),
          ),
        ],
      ),
    );
  }
}