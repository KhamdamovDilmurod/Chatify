import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MediaService {
  static MediaService instance = MediaService();

  final ImagePicker _picker = ImagePicker();

  Future<File?> getImageFromLibrary() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    // Return the image as a File if not null
    if (image != null) {
      return File(image.path);
    }

    // Return null if no image is selected
    return null;
  }
}