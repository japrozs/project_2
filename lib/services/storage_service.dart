import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  /// Uploads a hike photo for the given user.
  /// Returns the download URL on success.
  static Future<String> uploadHikePhoto({
    required String userId,
    required File file,
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('hikes/$userId/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': userId},
    );

    final uploadTask = await ref.putFile(file, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploads a user avatar photo.
  /// Returns the download URL on success.
  static Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    // Avatars overwrite the same path so storage stays clean.
    final ref = _storage.ref().child('avatars/$userId/profile.jpg');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': userId},
    );

    final uploadTask = await ref.putFile(file, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploads a photo attached to a trail condition report.
  static Future<String> uploadReportPhoto({
    required String userId,
    required String trailId,
    required File file,
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('reports/$trailId/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': userId, 'trailId': trailId},
    );

    final uploadTask = await ref.putFile(file, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploads a community post photo.
  static Future<String> uploadPostPhoto({
    required String userId,
    required File file,
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('posts/$userId/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': userId},
    );

    final uploadTask = await ref.putFile(file, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Deletes a file by its download URL.
  static Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may not exist; safe to ignore.
    }
  }
}
