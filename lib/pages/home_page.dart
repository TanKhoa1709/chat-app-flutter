import 'package:chat_app_flutter/components/my_drawer.dart';
import 'package:chat_app_flutter/components/user_tile.dart';
import 'package:chat_app_flutter/pages/chat_page.dart';
import 'package:chat_app_flutter/pages/incoming_call_page.dart';
import 'package:chat_app_flutter/services/auth/auth_service.dart';
import 'package:chat_app_flutter/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  bool _isIncomingCallShowing = false;

  // List of users
  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStreamExceptBlockedUsers(),
      builder: (context, snapshot) {
        // Error
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        // List view
        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  // Individual list tile for user
  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    if (userData['email'] != _authService.getCurrentUser()?.email) {
      return UserTile(
        text: userData['email'],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                  receiverEmail: userData['email'],
                  receiverID: userData['uid']),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }

  Widget _buildListenCall(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('calls')
          .where('receiverId',
              isEqualTo: currentUserId) // Chỉ bắt cuộc gọi gửi cho MÌNH
          .snapshots(),
      builder: (context, snapshot) {
        // Nếu có dữ liệu và có cuộc gọi đang chờ
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var callDoc = snapshot.data!.docs.first;
          var data = callDoc.data() as Map<String, dynamic>;

          // Chỉ hiện nếu chưa có ai trả lời
          if (data['answer'] == null) {
            // Nếu màn hình đang hiện rồi thì THÔI
            if (_isIncomingCallShowing) {
              return const SizedBox.shrink();
            }

            // Dùng Future.microtask để chuyển màn hình an toàn
            Future.microtask(() {
              if (!context.mounted) return;

              _isIncomingCallShowing = true;

              // Kiểm tra xem màn hình đang hiển thị có phải IncomingCallPage chưa để tránh mở chồng chéo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IncomingCallPage(
                    callId: callDoc.id,
                    callerId: data['senderId'],
                    callerName: data['senderName'] ?? "Người lạ",
                  ),
                ),
              ).then((_) {
                // Khi màn hình IncomingCallPage đóng lại (dù nghe hay từ chối)
                // Reset cờ về false để sẵn sàng cho lần gọi sau
                _isIncomingCallShowing = false;
              });
            });
          }
        }
        // Widget này tàng hình, không ảnh hưởng giao diện
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _authService.getCurrentUser()!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('H O M E'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      drawer: MyDrawer(),
      body: Stack(
        children: [
          _buildUserList(),
          _buildListenCall(currentUserId),
        ],
      ),
    );
  }
}
