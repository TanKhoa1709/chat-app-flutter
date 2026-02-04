import 'package:chat_app_flutter/pages/call_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IncomingCallPage extends StatelessWidget {
  final String callId; // ID của phòng gọi
  final String callerId; // ID người gọi
  final String callerName; // Tên người gọi

  const IncomingCallPage({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
  });

  void _declineCall(BuildContext context) async {
    // 1. Xóa phòng gọi trên Firestore
    await FirebaseFirestore.instance.collection('calls').doc(callId).delete();
    // 2. Đóng màn hình này
    if (context.mounted) Navigator.pop(context);
  }

  void _acceptCall(BuildContext context) async {
    // 1. Đóng màn hình chờ
    Navigator.pop(context);

    // 2. Chuyển sang màn hình gọi
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          roomId: callId,
          receiverID: callerId,
          isCaller: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // Màu nền tối cho sang trọng
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Avatar người gọi
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Tên người gọi
            Text(
              "$callerName đang gọi...",
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Cuộc gọi video đến",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Spacer(),
            // Hàng nút bấm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // --- NÚT TỪ CHỐI ---
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "decline",
                      backgroundColor: Colors.redAccent,
                      onPressed: () => _declineCall(context),
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text("Từ chối",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),

                // --- NÚT TRẢ LỜI ---
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "accept",
                      backgroundColor: Colors.green,
                      onPressed: () => _acceptCall(context),
                      child: const Icon(Icons.call, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text("Trả lời",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
