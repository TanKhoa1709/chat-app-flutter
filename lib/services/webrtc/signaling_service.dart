import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class SignalingService {
  // Cấu hình máy chủ STUN
  // STUN giúp 2 máy tìm thấy nhau qua Internet
  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;
  Function(RTCPeerConnectionState)? onConnectionStateChange;

  FirebaseFirestore db = FirebaseFirestore.instance;

  // 1. Khởi tạo Camera & Mic
  Future<String> openUserMedia(
      RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) async {
    var stream = await navigator.mediaDevices.getUserMedia({
      'video': true, // Có lấy hình ảnh
      'audio': true, // Có lấy âm thanh
    });

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
    return stream.id;
  }

  // 2. Tạo phòng gọi (Dành cho Người Gọi - Caller)
  Future<String> createRoom(
    RTCVideoRenderer remoteRenderer,
    String receiverId,
    String senderId,
    String senderName,
  ) async {
    DocumentReference roomRef = db.collection('calls').doc();

    debugPrint('Create PeerConnection with configuration: $configuration');

    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    // Thêm hình ảnh/âm thanh của mình vào đường truyền
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Lắng nghe ICE Candidate (Địa chỉ đường mạng) và gửi lên Firestore
    var callerCandidatesCollection = roomRef.collection('callerCandidates');
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      debugPrint('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };

    // Tạo lời mời (Offer)
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    debugPrint('Created offer: $offer');

    // Gửi lời mời lên Firestore
    Map<String, dynamic> roomWithOffer = {
      'offer': offer.toMap(),
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await roomRef.set(roomWithOffer);

    // Gán ID phòng để sau này xóa
    roomId = roomRef.id;

    // Khi người kia trả lời, video của họ sẽ hiện lên -> gắn vào remoteRenderer
    peerConnection?.onTrack = (RTCTrackEvent event) {
      debugPrint('Got remote track: ${event.streams[0]}');
      event.streams[0].getTracks().forEach((track) {
        remoteStream?.addTrack(track);
      });
    };

    // Lắng nghe Phản hồi (Answer) từ người nghe
    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint("Phòng đã bị xóa hoặc dữ liệu trống.");
        return;
      }
      debugPrint('Got updated room: ${snapshot.data()}');
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection != null &&
          peerConnection?.getRemoteDescription() != null &&
          data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        debugPrint("Someone tried to connect");
        await peerConnection?.setRemoteDescription(answer);
      }
    });

    // Lắng nghe các Candidate của người nghe
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          debugPrint('Got new remote ICE candidate: ${jsonEncode(data)}');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return roomId!;
  }

  // 3. Vào phòng gọi (Dành cho Người Nghe - Callee)
  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
    DocumentReference roomRef = db.collection('calls').doc(roomId);
    var roomSnapshot = await roomRef.get();
    debugPrint('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      debugPrint('Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Lắng nghe Candidate của mình và gửi lên Firestore (vào kho của Callee)
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        calleeCandidatesCollection.add(candidate.toMap());
      };

      peerConnection?.onTrack = (RTCTrackEvent event) {
        debugPrint('Got remote track: ${event.streams[0]}');
        event.streams[0].getTracks().forEach((track) {
          remoteStream?.addTrack(track);
        });
      };

      // Lấy Offer của người gọi về
      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Tạo câu trả lời (Answer)
      var answer = await peerConnection!.createAnswer();
      debugPrint('Created Answer $answer');

      await peerConnection!.setLocalDescription(answer);

      // Gửi câu trả lời lên Firestore
      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);

      // Lắng nghe Candidate của người gọi để kết nối
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          debugPrint(data.toString());
          debugPrint('Got new remote ICE candidate: ${jsonEncode(data)}');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      });
    }
  }

  // 4. Kết thúc cuộc gọi
  Future<void> hangUp(RTCVideoRenderer localRenderer, String roomId) async {
    // 1. Dừng Camera/Mic
    if (localRenderer.srcObject != null) {
      localRenderer.srcObject!.getTracks().forEach((track) => track.stop());
      localRenderer.srcObject = null;
    }

    // 2. Đóng PeerConnection và giải phóng tài nguyên WebRTC
    try {
      if (peerConnection != null) {
        await peerConnection!.close();
        peerConnection = null;
      }
      if (localStream != null) {
        await localStream!.dispose();
        localStream = null;
      }
      if (remoteStream != null) {
        await remoteStream!.dispose();
        remoteStream = null;
      }
    } catch (e) {
      debugPrint("Lỗi giải phóng tài nguyên WebRTC: $e");
    }

    if (roomId.isEmpty) return;

    var db = FirebaseFirestore.instance;
    var roomRef = db.collection('calls').doc(roomId);

    try {
      // 3. Xóa các Sub-collections (Candidates)
      // Cần xóa từng document bên trong sub-collection
      var callerCandidates = await roomRef.collection('callerCandidates').get();
      for (var doc in callerCandidates.docs) {
        await doc.reference.delete();
      }

      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      for (var doc in calleeCandidates.docs) {
        await doc.reference.delete();
      }

      // 4. Cuối cùng xóa Document cha
      await roomRef.delete();

      debugPrint("Đã xóa phòng gọi");
    } catch (e) {
      debugPrint("Lỗi khi dọn dẹp phòng: $e");
    }
  }

  // Hàm phụ trợ để log trạng thái
  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('Connection state change: $state');
      onConnectionStateChange?.call(state);
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint('Signaling state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      debugPrint("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}
