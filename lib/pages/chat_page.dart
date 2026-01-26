import 'package:chat_app_flutter/components/chat_bubble.dart';
import 'package:chat_app_flutter/components/my_textfield.dart';
import 'package:chat_app_flutter/services/auth/auth_service.dart';
import 'package:chat_app_flutter/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(receiverEmail),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Column(
        children: [
          // List of messages
          Expanded(
            child: _buildMessageList(),
          ),

          // User input
          _buildUserInput(),
        ],
      ),
    );
  }

  // List of messages
  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(receiverID, senderID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  // Individual message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> messageData = doc.data() as Map<String, dynamic>;

    bool isCurrentUser =
        messageData['sender_id'] == _authService.getCurrentUser()!.uid;

    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: messageData['message'],
            isCurrentUser: isCurrentUser,
          ),
        ],
      ),
    );
  }

  // User input
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Row(
        children: [
          Expanded(
            child: MyTextField(
                hintText: 'Enter message...',
                obscureText: false,
                controller: _messageController),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20.0),
            ),
            margin: EdgeInsets.only(right: 20.0),
            child: IconButton(
              onPressed: _sendMessage,
              icon: Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
