import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Upload file and return download URL (soporta web y móvil)
  Future<String> uploadFile({
    File? file,
    Uint8List? bytes,
    required String folder,
    String? fileName,
  }) async {
    try {
      if (file == null && bytes == null) {
        throw Exception('Either file or bytes must be provided');
      }

      String finalFileName = fileName ?? '${_uuid.v4()}.pdf';
      String path = '$folder/$finalFileName';

      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask;

      if (bytes != null) {
        // Web: usar bytes
        uploadTask = ref.putData(bytes);
      } else {
        // Móvil: usar file
        uploadTask = ref.putFile(file!);
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // Upload CV
  Future<String> uploadCV({
    File? file,
    Uint8List? bytes,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      bytes: bytes,
      folder: 'cvs/$userId',
      fileName: 'cv_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // Upload certification
  Future<String> uploadCertification({
    File? file,
    Uint8List? bytes,
    required String userId,
    String? fileName,
  }) async {
    return uploadFile(
      file: file,
      bytes: bytes,
      folder: 'certifications/$userId',
      fileName: fileName,
    );
  }

  // Upload teaching material
  Future<String> uploadTeachingMaterial({
    File? file,
    Uint8List? bytes,
    required String userId,
    String? originalFileName,
  }) async {
    return uploadFile(
      file: file,
      bytes: bytes,
      folder: 'materials/$userId',
      fileName: originalFileName,
    );
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto({
    required File file,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'profile_photos/$userId',
      fileName: 'profile.jpg',
    );
  }

  // Upload institution logo
  Future<String> uploadInstitutionLogo({
    required File file,
    required String institutionId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'institution_logos/$institutionId',
      fileName: 'logo.png',
    );
  }

  // Delete all files stored for a user (best-effort, used on account deletion)
  Future<void> deleteUserFiles(String userId) async {
    const folders = [
      'cvs',
      'certifications',
      'materials',
      'profile_photos',
      'institution_logos',
    ];
    for (final folder in folders) {
      try {
        final result = await _storage.ref().child('$folder/$userId').listAll();
        for (final item in result.items) {
          await item.delete();
        }
      } catch (e) {
        // Folder may not exist for this user — ignore.
        print('Skipping $folder for $userId: $e');
      }
    }
  }

  // Delete file by URL
  Future<void> deleteFileByUrl(String url) async {
    try {
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String url) async {
    try {
      Reference ref = _storage.refFromURL(url);
      return await ref.getMetadata();
    } catch (e) {
      print('Error getting file metadata: $e');
      rethrow;
    }
  }
}