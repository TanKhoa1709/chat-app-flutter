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
  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    DocumentReference roomRef =
        db.collection('calls').doc(); // Tạo ID ngẫu nhiên

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
    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
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
      debugPrint('Got updated room: ${snapshot.data()}');
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null &&
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
  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    for (var track in tracks) {
      track.stop();
    }

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }

    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var roomRef = db.collection('calls').doc(roomId);

      // Xóa các candidate (Optional: clean up data)
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      for (var document in calleeCandidates.docs) {
        document.reference.delete();
      }

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      for (var document in callerCandidates.docs) {
        document.reference.delete();
      }

      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  // Hàm phụ trợ để log trạng thái
  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('Connection state change: $state');
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
