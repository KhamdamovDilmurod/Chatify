//Packages
import 'package:cloud_firestore/cloud_firestore.dart';

//Models
import '../models/chat_message.dart';

const String USER_COLLECTION = "Users";
const String CHAT_COLLECTION = "Chats";
const String MESSAGES_COLLECTION = "messages";

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Constructor (currently empty)
  DatabaseService() {}

  Future<void> createUser(
      String uid, String email, String name, String imageURL) async {
    try {
      await _db.collection(USER_COLLECTION).doc(uid).set(
        {
          "email": email,
          "image": imageURL,
          "last_active": DateTime.now().toUtc(),
          "name": name,
        },
      );
    } catch (e) {
      print(e);
    }
  }

  // Method to retrieve a user document
  Future getUser(String uid) {
    return _db.collection(USER_COLLECTION).doc(uid).get();
  }

  // Method to update user's last seen time
  Future updateUserLastSeenTime(String uid) async {
    try {
      await _db.collection(USER_COLLECTION).doc(uid).update(
        {
          "last_active": DateTime.now().toUtc(),
        },
      );
    } catch (e) {
      print(e);
    }
  }
  Future<QuerySnapshot> getUsers({String? name}) {
    Query _query = _db.collection(USER_COLLECTION);
    if (name != null) {
      _query = _query
          .where("name", isGreaterThanOrEqualTo: name)
          .where("name", isLessThanOrEqualTo: name + "z");
    }
    return _query.get();
  }

  Stream<QuerySnapshot> getChatsForUser(String _uid) {
    return _db
        .collection(CHAT_COLLECTION)
        .where('members', arrayContains: _uid)
        .snapshots();
  }

  Future<QuerySnapshot> getLastMessageForChat(String _chatID) {
    return _db
        .collection(CHAT_COLLECTION)
        .doc(_chatID)
        .collection(MESSAGES_COLLECTION)
        .orderBy("sent_time", descending: true)
        .limit(1)
        .get();
  }

  Stream<QuerySnapshot> streamMessagesForChat(String _chatID) {
    return _db
        .collection(CHAT_COLLECTION)
        .doc(_chatID)
        .collection(MESSAGES_COLLECTION)
        .orderBy("sent_time", descending: false)
        .limitToLast(100)  // Optional: limit the number of messages to load
        .snapshots();
  }

  Future<void> addMessageToChat(String _chatID, ChatMessage _message) async {
    try {
      await _db
          .collection(CHAT_COLLECTION)
          .doc(_chatID)
          .collection(MESSAGES_COLLECTION)
          .add({
        ...(_message.toJson()),
        'sent_time': FieldValue.serverTimestamp(), // Override the client timestamp
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateChatData(
      String _chatID, Map<String, dynamic> _data) async {
    try {
      await _db.collection(CHAT_COLLECTION).doc(_chatID).update(_data);
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteChat(String _chatID) async {
    try {
      await _db.collection(CHAT_COLLECTION).doc(_chatID).delete();
    } catch (e) {
      print(e);
    }
  }

  Future<DocumentReference?> createChat(Map<String, dynamic> _data) async {
    try {
      // Check if chat already exists
      List<String> memberIds = List<String>.from(_data['members']);
      DocumentReference? existingChat = await checkExistingChat(memberIds, _data['is_group']);

      if (existingChat != null) {
        return existingChat;
      }

      // Create new chat if none exists
      DocumentReference _chat = await _db.collection(CHAT_COLLECTION).add(_data);
      return _chat;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<DocumentReference?> checkExistingChat(List<String> memberIds, bool isGroup) async {
    try {
      // Query chats containing at least one of the members
      QuerySnapshot querySnapshot = await _db
          .collection(CHAT_COLLECTION)
          .where('members', arrayContainsAny: memberIds)
          .where('is_group', isEqualTo: isGroup)
          .get();

      for (var doc in querySnapshot.docs) {
        List<dynamic> chatMembers = doc.get('members');

        // For one-on-one chats
        if (!isGroup && chatMembers.length == 2) {
          bool allMembersMatch = memberIds.every(
                  (id) => chatMembers.contains(id)
          );
          if (allMembersMatch) {
            return doc.reference;
          }
        }

        // For group chats
        else if (isGroup && chatMembers.length == memberIds.length) {
          bool allMembersMatch = memberIds.every(
                  (id) => chatMembers.contains(id)
          );
          if (allMembersMatch) {
            return doc.reference;
          }
        }
      }

      return null;
    } catch (e) {
      print("Error checking existing chat: $e");
      return null;
    }
  }

  // Helper method to get all chats for a specific set of members
  Future<QuerySnapshot> getChatsByMembers(List<String> memberIds) {
    return _db
        .collection(CHAT_COLLECTION)
        .where('members', arrayContainsAny: memberIds)
        .get();
  }

}