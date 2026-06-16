import 'dart:async';
import 'package:chat_app_flutter/pages/call_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IncomingCallPage extends StatefulWidget {
  final String callId; // ID của phòng gọi
  final String callerId; // ID người gọi
  final String callerName; // Tên người gọi

  const IncomingCallPage({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
  });

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  StreamSubscription? _callStreamSubscription;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _listenToCallCancellation();
  }

  @override
  void dispose() {
    _callStreamSubscription?.cancel();
    super.dispose();
  }

  void _listenToCallCancellation() {
    _callStreamSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      // Nếu cuộc gọi không còn tồn tại trên Firestore -> Người gọi đã hủy
      if (!snapshot.exists) {
        debugPrint("Người gọi đã hủy cuộc gọi.");
        _exitPage(message: "Cuộc gọi đã bị hủy");
      }
    });
  }

  void _exitPage({String? message}) {
    if (_isExiting) return;
    _isExiting = true;
    _callStreamSubscription?.cancel();
    
    if (mounted) {
      Navigator.pop(context);
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  void _declineCall() async {
    if (_isExiting) return;
    _isExiting = true;
    _callStreamSubscription?.cancel();

    // 1. Xóa phòng gọi trên Firestore
    try {
      await FirebaseFirestore.instance.collection('calls').doc(widget.callId).delete();
    } catch (e) {
      debugPrint("Lỗi khi từ chối cuộc gọi: $e");
    }

    // 2. Đóng màn hình này
    if (mounted) Navigator.pop(context);
  }

  void _acceptCall() {
    if (_isExiting) return;
    _isExiting = true;
    _callStreamSubscription?.cancel();

    // 1. Đóng màn hình chờ
    if (mounted) {
      Navigator.pop(context);

      // 2. Chuyển sang màn hình gọi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            roomId: widget.callId,
            receiverID: widget.callerId,
            isCaller: false,
          ),
        ),
      );
    }
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
              "${widget.callerName} đang gọi...",
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
                      onPressed: _declineCall,
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
                      onPressed: _acceptCall,
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
