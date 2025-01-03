import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final String userId;

  VideoCallScreen({required this.roomId, required this.userId});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  bool _inCall = false;
  final _db = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _getUserMedia();
    await _createPeerConnection();
    _setupFirebaseListeners();
  }

  Future<void> _getUserMedia() async {
    await [Permission.camera, Permission.microphone].request();

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    });

    _localStream = stream;
    _localRenderer.srcObject = stream;
    setState(() {});
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(config, {});

    _peerConnection!.onIceCandidate = (candidate) {
      _sendIceCandidate(candidate);
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
        setState(() => _inCall = true);
      }
    };

    // Add local tracks to peer connection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  void _setupFirebaseListeners() {
    // Listen for remote description
    _db.child('rooms/${widget.roomId}/description').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        if (data['type'] == 'offer' && data['from'] != widget.userId) {
          _handleRemoteDescription(
              RTCSessionDescription(data['sdp'], data['type'])
          );
        } else if (data['type'] == 'answer' && data['from'] != widget.userId) {
          _peerConnection?.setRemoteDescription(
              RTCSessionDescription(data['sdp'], data['type'])
          );
        }
      }
    });

    // Listen for ICE candidates
    _db.child('rooms/${widget.roomId}/candidates').onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        if (data['from'] != widget.userId) {
          _peerConnection?.addCandidate(RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ));
        }
      }
    });
  }

  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    await _db.child('rooms/${widget.roomId}/candidates').push().set({
      'from': widget.userId,
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  Future<void> _createOffer() async {
    final description = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(description);

    await _db.child('rooms/${widget.roomId}/description').set({
      'type': description.type,
      'sdp': description.sdp,
      'from': widget.userId,
    });
  }

  Future<void> _handleRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection?.setRemoteDescription(description);

    if (description.type == 'offer') {
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _db.child('rooms/${widget.roomId}/description').set({
        'type': answer.type,
        'sdp': answer.sdp,
        'from': widget.userId,
      });
    }
  }

  Future<void> _endCall() async {
    // await _peerConnection?.close();
    // await _db.child('rooms/${widget.roomId}').remove();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.dispose();
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              
              children: [
                Expanded(
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                  ),
                ),
                // Expanded(
                //   child: RTCVideoView(
                //     _remoteRenderer,
                //     mirror: true,
                //   ),
                //
                // ),
                Expanded(child: Center(child: Text(_inCall ? "Connected" : "Texnik ishlar amalga oshirilmoqda... \n Iltimos kuting...",textAlign: TextAlign.center,style: TextStyle(color: Colors.white),))),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "call",
                  onPressed: _createOffer,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.phone),
                ),
                FloatingActionButton(
                  heroTag: "end",
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.call_end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}