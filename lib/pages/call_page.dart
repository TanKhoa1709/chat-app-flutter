import 'package:chat_app_flutter/services/auth/auth_service.dart';
import 'package:chat_app_flutter/services/chat/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/webrtc/signaling_service.dart';

class CallPage extends StatefulWidget {
  final String roomId;
  final String receiverID;
  final bool isCaller; // true: Người gọi, false: Người nghe

  const CallPage({
    super.key,
    required this.roomId,
    this.isCaller = true,
    required this.receiverID,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  // 1. Khai báo 2 cái "Tivi" (Renderer)
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  String? _roomId;

  // Khai báo SignalingService
  final SignalingService _signaling = SignalingService();

  // Trạng thái Mic/Cam
  bool _isMicOn = true;
  bool _isCameraOn = true;

  @override
  void initState() {
    super.initState();
    // Khởi tạo ngay khi mở màn hình
    _roomId = widget.roomId;
    initRenderers();
  }

  Future<void> initRenderers() async {
    // Xin quyền Camera/Mic
    await [Permission.camera, Permission.microphone].request();

    // Kiểm tra xem user đã đồng ý chưa
    var camStatus = await Permission.camera.status;
    var micStatus = await Permission.microphone.status;

    if (!camStatus.isGranted || !micStatus.isGranted) {
      debugPrint("Người dùng từ chối quyền Camera/Mic!");
      return; // Dừng luôn, không chạy tiếp để tránh lỗi
    }

    // 1. Bật 2 cái Tivi lên
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Lấy thông tin người dùng hiện tại
    final user = AuthService().getCurrentUser();
    String senderId = user!.uid;
    String senderName = user.email!;

    // 2. Gắn sự kiện: Khi có luồng video mới từ bên kia -> Cập nhật giao diện
    _signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    // 3. Mở Camera & Mic của mình trước
    await _signaling.openUserMedia(_localRenderer, _remoteRenderer);

    // 4. Phân luồng: Người gọi hay Người nghe?
    if (widget.isCaller) {
      // Nếu là người gọi -> Tạo phòng
      // Dùng roomId truyền vào để set vào Firestore
      _roomId = await _signaling.createRoom(
          _remoteRenderer, widget.receiverID, senderId, senderName);
      setState(() {});
    } else {
      // Nếu là người nghe -> Vào phòng
      await _signaling.joinRoom(widget.roomId, _remoteRenderer);
    }

    setState(() {});
  }

  @override
  void dispose() {
    // Dọn dẹp khi thoát màn hình
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    if (_roomId != null) {
      _signaling.hangUp(_localRenderer, _roomId!);
    }
    super.dispose();
  }

  // Hàm bật/tắt Mic
  void _toggleMic() {
    // Lấy track âm thanh đầu tiên và đảo ngược trạng thái
    _localRenderer.srcObject?.getAudioTracks().forEach((track) {
      track.enabled = !_isMicOn;
    });
    setState(() => _isMicOn = !_isMicOn);
  }

  // Hàm bật/tắt Camera
  void _toggleCamera() {
    // Lấy track hình ảnh đầu tiên và đảo ngược trạng thái
    _localRenderer.srcObject?.getVideoTracks().forEach((track) {
      track.enabled = !_isCameraOn;
    });
    setState(() => _isCameraOn = !_isCameraOn);
  }

  void _hangUp() async {
    // 1. Chỉ người gọi (Caller) mới lưu log
    if (widget.isCaller) {
      ChatService().sendCallLog(
        widget.receiverID, // ID người nhận
        "Cuộc gọi video", // Nội dung hiển thị
      );
    }
    // 2. Dọn dẹp Signaling
    if (_roomId == null) {
      debugPrint("LỖI: _roomId bị NULL -> Không thể xóa!");
    } else if (_roomId!.isEmpty) {
      debugPrint("LỖI: _roomId bị RỖNG -> Không thể xóa!");
    } else {
      debugPrint("ID hợp lệ. Đang gọi lệnh xóa cho phòng: $_roomId");
      _signaling.hangUp(_localRenderer, _roomId!);
    }
    // 3. Thoát màn hình
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LỚP 1: Video người bên kia (Full màn hình)
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer,
              objectFit:
                  RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, // Tràn viền
            ),
          ),

          // LỚP 2: Video của mình (Góc phải trên)
          Positioned(
            right: 20,
            top: 50,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white38),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true, // Soi gương (lật ngược lại cho thuận mắt)
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),

          // LỚP 3: Các nút điều khiển (Ở dưới đáy)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Nút Mic
                IconButton(
                  onPressed: _toggleMic,
                  style: IconButton.styleFrom(
                    backgroundColor: _isMicOn ? Colors.white24 : Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: Icon(
                    _isMicOn ? Icons.mic : Icons.mic_off,
                    color: _isMicOn ? Colors.white : Colors.black,
                  ),
                ),

                // Nút Cúp máy
                IconButton(
                  onPressed: () => _hangUp(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon:
                      const Icon(Icons.call_end, color: Colors.white, size: 32),
                ),

                // Nút Camera
                IconButton(
                  onPressed: _toggleCamera,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        _isCameraOn ? Colors.white24 : Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: Icon(
                    _isCameraOn ? Icons.videocam : Icons.videocam_off,
                    color: _isCameraOn ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Loading khi chưa kết nối
          if (_remoteRenderer.srcObject == null && !widget.isCaller)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
