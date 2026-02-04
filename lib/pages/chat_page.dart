import 'package:chat_app_flutter/components/chat_bubble.dart';
import 'package:chat_app_flutter/components/my_textfield.dart';
import 'package:chat_app_flutter/pages/call_page.dart';
import 'package:chat_app_flutter/services/auth/auth_service.dart';
import 'package:chat_app_flutter/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  // Text field controller
  final TextEditingController _messageController = TextEditingController();

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // Instance of ChatService and AuthService
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // Text field focus node
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Register observer
    WidgetsBinding.instance.addObserver(this);

    // Wait a bit for list view to be built, then scroll to the bottom
    Future.delayed(Duration(milliseconds: 500), () => scrollDown());
  }

  @override
  void didChangeMetrics() {
    // Get the height of the keyboard
    final bottomInset = View.of(context).viewInsets.bottom;

    // If the keyboard is open, scroll to the bottom
    if (bottomInset > 0.0) {
      // Cause a delay so that the keyboard has time to show up
      // then the amount of remaining space will be calculated,
      // then scroll to the bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        scrollDown();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    focusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  // Send message
  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverID, message);
      _messageController.clear();
    }
    scrollDown();
  }

  void _callUser() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          // Truyền chuỗi rỗng vì CallPage sẽ tự sinh ID mới trong initRenderers
          roomId: "",

          // ID người mình muốn gọi (để gửi thông báo cho họ)
          receiverID: widget.receiverID,

          // KHẲNG ĐỊNH: Tôi là người gọi
          isCaller: true,
        ),
      ),
    );
  }

  // List of messages
  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, senderID),
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
          controller: _scrollController,
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

    String type = messageData['type'] ?? 'text';

    if (type == 'call') {
      return Container(
        alignment: alignment,
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.call),
                SizedBox(width: 10),
                ChatBubble(
                  message: messageData['message'],
                  isCurrentUser: isCurrentUser,
                  messageID: doc.id,
                  userID: messageData['sender_id'],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        alignment: alignment,
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ChatBubble(
              message: messageData['message'],
              isCurrentUser: isCurrentUser,
              messageID: doc.id,
              userID: messageData['sender_id'],
            ),
          ],
        ),
      );
    }
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
                focusNode: focusNode,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.receiverEmail),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, size: 28),
            onPressed: _callUser,
          ),
        ],
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
}
