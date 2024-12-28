import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  TEXT,
  IMAGE,
  UNKNOWN,
}

class ChatMessage {
  final String senderID;
  final MessageType type;
  String content;
  final Timestamp sentTime;  // Changed from DateTime to Timestamp

  ChatMessage({
    required this.content,
    required this.type,
    required this.senderID,
    required this.sentTime,  // Now accepts Timestamp
  });

  factory ChatMessage.fromJSON(Map<String, dynamic> _json) {
    MessageType _messageType;
    switch (_json["type"]) {
      case "text":
        _messageType = MessageType.TEXT;
        break;
      case "image":
        _messageType = MessageType.IMAGE;
        break;
      default:
        _messageType = MessageType.UNKNOWN;
    }
    return ChatMessage(
      content: _json["content"],
      type: _messageType,
      senderID: _json["sender_id"],
      sentTime: _json["sent_time"], // Directly use Timestamp from Firestore
    );
  }

  Map<String, dynamic> toJson() {
    String _messageType;
    switch (type) {
      case MessageType.TEXT:
        _messageType = "text";
        break;
      case MessageType.IMAGE:
        _messageType = "image";
        break;
      default:
        _messageType = "";
    }
    return {
      "content": content,
      "type": _messageType,
      "sender_id": senderID,
      "sent_time": sentTime,  // Directly store Timestamp
    };
  }

  // Helper method to get DateTime if needed
  DateTime get sentDateTime => sentTime.toDate();
}