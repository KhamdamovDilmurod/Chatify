import 'package:cloud_firestore/cloud_firestore.dart';

class VideoCallModel {
  final String callerId;
  final String receiverId;
  final String channelId;
  final String callerName;
  final bool isActive;
  final DateTime timestamp;

  VideoCallModel({
    required this.callerId,
    required this.receiverId,
    required this.channelId,
    required this.callerName,
    required this.isActive,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'receiverId': receiverId,
      'channelId': channelId,
      'callerName': callerName,
      'isActive': isActive,
      'timestamp': timestamp,
    };
  }

  factory VideoCallModel.fromMap(Map<String, dynamic> map) {
    return VideoCallModel(
      callerId: map['callerId'],
      receiverId: map['receiverId'],
      channelId: map['channelId'],
      callerName: map['callerName'],
      isActive: map['isActive'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}