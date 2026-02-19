import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Upload file and return download URL - funciona para móvil y web
  Future<String> uploadFile({
    File? file,
    Uint8List? bytes,
    required String folder,
    required String fileName,
  }) async {
    try {
      if (file == null && bytes == null) {
        throw Exception('Either file or bytes must be provided');
      }

      String path = '$folder/$fileName';
      Reference ref = _storage.ref().child(path);

      UploadTask uploadTask;
      if (kIsWeb && bytes != null) {
        // Web: usar bytes
        uploadTask = ref.putData(bytes);
      } else if (file != null) {
        // Móvil: usar file
        uploadTask = ref.putFile(file);
      } else {
        throw Exception('Invalid upload parameters for platform');
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // Upload teaching material - ahora soporta web y móvil
  Future<String> uploadTeachingMaterial({
    File? file,
    Uint8List? bytes,
    required String userId,
    required String originalFileName,
  }) async {
    String fileExtension = originalFileName.split('.').last;
    String fileName = '${_uuid.v4()}.$fileExtension';

    return uploadFile(
      file: file,
      bytes: bytes,
      folder: 'materials/$userId',
      fileName: fileName,
    );
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
    required String fileName,
  }) async {
    return uploadFile(
      file: file,
      bytes: bytes,
      folder: 'certifications/$userId',
      fileName: fileName,
    );
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto({
    File? file,
    Uint8List? bytes,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      bytes: bytes,
      folder: 'profile_photos',
      fileName: '$userId.jpg',
    );
  }

  // Upload institution logo
  Future<String> uploadInstitutionLogo({
    File? file,
    Uint8List? bytes,
    required String institutionId,
  }) async {
    return uploadFile(
      file: file,
      bytes: bytes,
      folder: 'institution_logos',
      fileName: '$institutionId.png',
    );
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
