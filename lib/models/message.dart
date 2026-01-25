import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
  });

  // Convert a Message object to a Map
  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderID,
      'sender_email': senderEmail,
      'receiver_id': receiverID,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
