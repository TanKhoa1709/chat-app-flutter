import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  // Instance of firestore
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Get users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    });
  }
}
