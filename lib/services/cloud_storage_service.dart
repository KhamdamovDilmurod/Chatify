import 'dart:io';

// Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

const String USER_COLLECTION = "Users";

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Save user image to Firebase Storage
  Future<String?> saveUserImageToStorage(
      String uid, File file) async {
    try {
      Reference ref = _storage.ref().child('images/users/$uid/profile.${file.path.split('.').last}');

      UploadTask task = ref.putFile(File(file.path));

      return await task.then(
            (result) => result.ref.getDownloadURL(),
      );
    } catch (e) {
      print('Error saving user image: $e');
      return null;
    }
  }

  /// Save chat image to Firebase Storage
  Future<String?> saveChatImageToStorage(
      String chatID, String userID, File file) async {
    try {
      Reference ref = _storage.ref().child(
          'images/chats/$chatID/${userID}_${Timestamp.now().millisecondsSinceEpoch}.${file.path.split('.').last}'
      );

      UploadTask task = ref.putFile(File(file.path));

      return await task.then(
            (result) => result.ref.getDownloadURL(),
      );
    } catch (e) {
      print('Error saving chat image: $e');
      return null;
    }
  }

  /// Save voice message to Firebase Storage
  Future<String?> saveAudioToStorage(
      String chatID, String userID, File file) async {
    try {
      Reference ref = _storage.ref().child(
          'audios/chats/$chatID/${userID}_${Timestamp.now().millisecondsSinceEpoch}.${file.path.split('.').last}'
      );

      UploadTask task = ref.putFile(File(file.path));

      return await task.then(
            (result) => result.ref.getDownloadURL(),
      );
    } catch (e) {
      print('Error saving chat voice message: $e');
      return null;
    }
  }
}