import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  /// Prompts the user to select an image from their local system (PC file dialog / gallery / camera).
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );
      return pickedFile;
    } catch (e) {
      debugPrint('[StorageService] pickImage error: $e');
      throw Exception('Failed to pick image from system: $e');
    }
  }

  /// Converts image file bytes to an optimized Data URI that stores directly and works
  /// across all platforms with 0 external network dependencies, 0 CORS issues, and 0 billing requirements.
  Future<String> encodeImageAsDataUrl({
    required Uint8List bytes,
    String? fileExtension,
  }) async {
    try {
      final ext = fileExtension?.replaceFirst('.', '').toLowerCase() ?? 'jpeg';
      final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
      final base64String = base64Encode(bytes);
      return 'data:$mime;base64,$base64String';
    } catch (e) {
      debugPrint('[StorageService] encodeImage error: $e');
      throw Exception('Failed to encode image: $e');
    }
  }

  /// Convenience method: picks image from system and converts it into a ready-to-use profile avatar URL.
  /// Returns the avatar URL string, or null if the user canceled the file picker.
  Future<String?> pickAndUploadAvatar(String uid) async {
    final XFile? file = await pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    final Uint8List bytes = await file.readAsBytes();
    final String extension = file.name.contains('.') ? file.name.split('.').last : 'jpg';

    return await encodeImageAsDataUrl(
      bytes: bytes,
      fileExtension: extension,
    );
  }
}
