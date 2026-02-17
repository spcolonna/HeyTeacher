import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  
  // Upload file and return download URL
  Future<String> uploadFile({
    required File file,
    required String folder,
    String? fileName,
  }) async {
    try {
      String fileExtension = file.path.split('.').last;
      String finalFileName = fileName ?? '${_uuid.v4()}.$fileExtension';
      String path = '$folder/$finalFileName';
      
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }
  
  // Upload CV
  Future<String> uploadCV(File file, String userId) async {
    return uploadFile(
      file: file,
      folder: 'cvs/$userId',
      fileName: 'cv_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
  
  // Upload certification
  Future<String> uploadCertification(File file, String userId) async {
    return uploadFile(
      file: file,
      folder: 'certifications/$userId',
    );
  }
  
  // Upload teaching material
  Future<String> uploadTeachingMaterial(File file, String userId) async {
    return uploadFile(
      file: file,
      folder: 'materials/$userId',
    );
  }
  
  // Upload profile photo
  Future<String> uploadProfilePhoto(File file, String userId) async {
    return uploadFile(
      file: file,
      folder: 'profile_photos',
      fileName: '$userId.jpg',
    );
  }
  
  // Upload institution logo
  Future<String> uploadInstitutionLogo(File file, String institutionId) async {
    return uploadFile(
      file: file,
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
