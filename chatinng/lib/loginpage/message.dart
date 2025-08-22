import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderID,
    required this.message,
    required this.receiverID,
    required this.senderEmail,
    required this.timestamp
  });

  Map<String, dynamic> toMap(){
    return {
      'senderID' : senderID,
      'recieverID' : receiverID,
      'senderEmail' : senderEmail,
      'message' : message,
      'timestamp' : timestamp

    };
  }
}