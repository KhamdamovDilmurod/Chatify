import '../models/chat_user.dart';
import '../models/chat_message.dart';

class Chat {
  final String uid;
  final String currentUserUid;
  final bool activity;
  final bool group;
  final List<ChatUser> members;
  List<ChatMessage> messages;

  late final List<ChatUser> _recepients;

  Chat({
    required this.uid,
    required this.currentUserUid,
    required this.members,
    required this.messages,
    required this.activity,
    required this.group,
  }) {
    _recepients = members.where((_i) => _i.uid != currentUserUid).toList();
  }

  List<ChatUser> recepients() {
    return _recepients;
  }

  String title() {
    // Handle cases where there are no recipients
    if (_recepients.isEmpty) {
      return group ? "Group Chat" : "Unknown Chat";
    }

    // For non-group chats, use the first recipient's name
    if (!group) {
      return _recepients.first.name;
    }

    // For group chats, join recipient names
    return _recepients.map((_user) => _user.name).join(", ");
  }

  String imageURL() {
    if (_recepients.isNotEmpty) {
      return !group ? _recepients.first.imageURL : "https://e7.pngegg.com/pngimages/380/670/png-clipart-group-chat-logo-blue-area-text-symbol-metroui-apps-live-messenger-alt-2-blue-text.png";
    } else {
      return "https://via.placeholder.com/150"; // or any other default image URL
    }
  }
}
