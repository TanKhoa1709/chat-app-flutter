import 'package:chat_app_flutter/services/auth/auth_service.dart';
import 'package:chat_app_flutter/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final String receiverEmail;
  final String receiverID;

  ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  // Text field controller
  final TextEditingController _messageController = TextEditingController();

  // Instance of ChatService and AuthService
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // Send message
  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await _chatService.sendMessage(receiverID, message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverEmail),
      ),
    );
  }
}
