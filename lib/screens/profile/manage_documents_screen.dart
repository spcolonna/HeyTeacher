import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../models/teacher_profile.dart';
import '../../services/firestore_wrapper.dart';
import '../../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDocumentsScreen extends StatefulWidget {
  const ManageDocumentsScreen({super.key});

  @override
  State<ManageDocumentsScreen> createState() => _ManageDocumentsScreenState();
}

class _ManageDocumentsScreenState extends State<ManageDocumentsScreen> {
  final StorageService _storageService = StorageService();

  TeacherProfile? _profile;
  bool _isLoading = true;
  bool _isUploading = false;
  String _uploadingType = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot doc =
          await FirestoreWrapper.getDocument('teacher_profiles', user.uid);

      if (doc.exists) {
        setState(() {
          _profile = TeacherProfile.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadCV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb,
      );

      if (result == null) return;

      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) return;

      setState(() {
        _isUploading = true;
        _uploadingType = 'CV';
      });

      String cvUrl = await _storageService.uploadCV(
        file: kIsWeb ? null : File(result.files.single.path!),
        bytes: kIsWeb ? result.files.single.bytes : null,
        userId: user.uid,
      );

      // Update profile with CV URL
      await FirestoreWrapper.updateDocument('teacher_profiles', user.uid, {
        'cvUrl': cvUrl,
        'updatedAt': Timestamp.now(),
      });

      await _loadProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading CV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadCertification() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: kIsWeb,
      );

      if (result == null) return;

      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) return;

      setState(() {
        _isUploading = true;
        _uploadingType = 'Certification';
      });

      String certUrl = await _storageService.uploadCertification(
        file: kIsWeb ? null : File(result.files.single.path!),
        bytes: kIsWeb ? result.files.single.bytes : null,
        userId: user.uid,
        fileName: result.files.single.name,
      );

      // Add certification to profile
      List<String> certs = List.from(_profile?.certificationFiles ?? []);
      certs.add(certUrl);

      await FirestoreWrapper.updateDocument('teacher_profiles', user.uid, {
        'certificationFiles': certs,
        'updatedAt': Timestamp.now(),
      });

      await _loadProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certification uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading certification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteCertification(String certUrl, int index) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Certification'),
        content:
            const Text('Are you sure you want to delete this certification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) return;

      // Delete from storage
      await _storageService.deleteFileByUrl(certUrl);

      // Remove from profile
      List<String> certs = List.from(_profile?.certificationFiles ?? []);
      certs.removeAt(index);

      await FirestoreWrapper.updateDocument('teacher_profiles', user.uid, {
        'certificationFiles': certs,
        'updatedAt': Timestamp.now(),
      });

      await _loadProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting certification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openDocument(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // CV Section
          const Text(
            'Curriculum Vitae (CV)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your CV to help institutions learn more about your experience.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),

          if (_profile?.cvUrl != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf,
                    color: Colors.red, size: 32),
                title: const Text('CV.pdf'),
                subtitle: const Text('Tap to view'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    // TODO: implement CV deletion
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CV deletion coming soon')),
                    );
                  },
                ),
                onTap: () => _openDocument(_profile!.cvUrl!),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No CV uploaded yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadCV,
            icon: _isUploading && _uploadingType == 'CV'
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_profile?.cvUrl != null ? 'Replace CV' : 'Upload CV'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 32),

          // Certifications Section
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Certifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _isUploading ? null : _uploadCertification,
                icon: _isUploading && _uploadingType == 'Certification'
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your teaching certifications (TESOL, Cambridge, etc.)',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),

          if (_profile?.certificationFiles.isEmpty ?? true)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No certifications uploaded yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._profile!.certificationFiles.asMap().entries.map((entry) {
              int index = entry.key;
              String certUrl = entry.value;
              bool isImage = certUrl.toLowerCase().contains('.jpg') ||
                  certUrl.toLowerCase().contains('.jpeg') ||
                  certUrl.toLowerCase().contains('.png');

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    isImage ? Icons.image : Icons.picture_as_pdf,
                    color: isImage ? Colors.blue : Colors.red,
                    size: 32,
                  ),
                  title: Text('Certification ${index + 1}'),
                  subtitle: Text(isImage ? 'Image file' : 'PDF file'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteCertification(certUrl, index),
                  ),
                  onTap: () => _openDocument(certUrl),
                ),
              );
            }),
        ],
      ),
    );
  }
}
