import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/teacher_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_wrapper.dart';
import '../../services/storage_service.dart';
import 'document_preview_screen.dart';
import '../../theme/theme.dart';

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
      final doc =
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadCV() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (result == null) return;

    final ext = result.files.single.name.split('.').last.toLowerCase();
    if (ext != 'pdf') {
      _showError('Only PDF files are allowed for CV.');
      return;
    }

    setState(() { _isUploading = true; _uploadingType = 'CV'; });
    try {
      final cvUrl = await _storageService.uploadCV(
        file: kIsWeb ? null : File(result.files.single.path!),
        bytes: kIsWeb ? result.files.single.bytes : null,
        userId: user.uid,
      );
      await FirestoreWrapper.updateDocument('teacher_profiles', user.uid, {
        'cvUrl': cvUrl,
        'updatedAt': Timestamp.now(),
      });
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV uploaded successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError('Error uploading CV: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteCV() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    final confirm = await _confirmDialog(
      title: 'Delete CV',
      message: 'Are you sure you want to delete your CV?',
    );
    if (confirm != true) return;

    try {
      await _storageService.deleteFileByUrl(_profile!.cvUrl!);
      await FirestoreWrapper.updateDocument('teacher_profiles', user.uid, {
        'cvUrl': null,
        'updatedAt': Timestamp.now(),
      });
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError('Error deleting CV: $e');
    }
  }

  Future<void> _uploadCertification() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    const allowed = ['pdf', 'jpg', 'jpeg', 'png'];
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowed,
      withData: kIsWeb,
    );
    if (result == null) return;

    final ext = result.files.single.name.split('.').last.toLowerCase();
    if (!allowed.contains(ext)) {
      _showError('Only PDF, JPG, or PNG files are allowed for certifications.');
      return;
    }

    final name = await _askCertName(result.files.single.name);
    if (name == null) return;

    setState(() { _isUploading = true; _uploadingType = 'Certification'; });
    try {
      final certUrl = await _storageService.uploadCertification(
        file: kIsWeb ? null : File(result.files.single.path!),
        bytes: kIsWeb ? result.files.single.bytes : null,
        userId: user.uid,
        fileName: result.files.single.name,
      );

      final files = List<String>.from(_profile?.certificationFiles ?? [])..add(certUrl);
      final names = List<String>.from(_profile?.certificationNames ?? [])..add(name);

      await FirestoreWrapper.updateDocument('teacher_profiles', user.uid, {
        'certificationFiles': files,
        'certificationNames': names,
        'updatedAt': Timestamp.now(),
      });
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certification uploaded'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError('Error uploading certification: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteCertification(String certUrl, int index) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    final confirm = await _confirmDialog(
      title: 'Delete Certification',
      message: 'Are you sure you want to delete this certification?',
    );
    if (confirm != true) return;

    try {
      await _storageService.deleteFileByUrl(certUrl);
      final files = List<String>.from(_profile?.certificationFiles ?? [])..removeAt(index);
      final names = List<String>.from(_profile?.certificationNames ?? []);
      if (index < names.length) names.removeAt(index);

      await FirestoreWrapper.updateDocument('teacher_profiles', user.uid, {
        'certificationFiles': files,
        'certificationNames': names,
        'updatedAt': Timestamp.now(),
      });
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certification deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError('Error deleting certification: $e');
    }
  }

  void _previewDocument(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(
          url: url,
          title: title,
          isImage: DocumentPreviewScreen.urlIsImage(url),
        ),
      ),
    );
  }

  Future<String?> _askCertName(String defaultName) async {
    final ctrl = TextEditingController(text: defaultName.replaceAll(RegExp(r'\.[^.]+$'), ''));
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this certificate'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Certificate name',
            hintText: 'e.g. CELTA 2022',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? defaultName : ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDialog({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(
            icon: Icons.picture_as_pdf,
            title: 'Curriculum Vitae',
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 4),
          Text(
            'Upload your CV so institutions can review your full background.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),

          if (_profile?.cvUrl != null)
            _DocumentCard(
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red.shade700,
              title: 'CV.pdf',
              subtitle: 'Tap preview to view',
              onPreview: () => _previewDocument(_profile!.cvUrl!, 'CV'),
              onDelete: _deleteCV,
            )
          else
            const _EmptyDocHint(label: 'No CV uploaded yet'),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadCV,
              icon: _isUploading && _uploadingType == 'CV'
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload_file),
              label: Text(_profile?.cvUrl != null ? 'Replace CV' : 'Upload CV (PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),

          const SizedBox(height: 36),

          Row(
            children: [
              Expanded(
                child: _buildSectionHeader(
                  icon: Icons.workspace_premium,
                  title: 'Certifications',
                  color: Theme.of(context).extension<AppDecor>()!.warning,
                ),
              ),
              TextButton.icon(
                onPressed: _isUploading ? null : _uploadCertification,
                icon: _isUploading && _uploadingType == 'Certification'
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upload your teaching certificates (TESOL, Cambridge, etc.). PDF, JPG or PNG.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),

          if (_profile?.certificationFiles.isEmpty ?? true)
            const _EmptyDocHint(label: 'No certifications uploaded yet')
          else
            ..._profile!.certificationFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              final name = (_profile!.certificationNames.length > index &&
                      _profile!.certificationNames[index].isNotEmpty)
                  ? _profile!.certificationNames[index]
                  : 'Certification ${index + 1}';
              final isImage = DocumentPreviewScreen.urlIsImage(url);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DocumentCard(
                  icon: isImage ? Icons.image : Icons.picture_as_pdf,
                  iconColor: isImage ? Colors.blue.shade600 : Colors.red.shade700,
                  title: name,
                  subtitle: isImage ? 'Image file' : 'PDF file',
                  onPreview: () => _previewDocument(url, name),
                  onDelete: () => _deleteCertification(url, index),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onPreview,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.visibility_outlined, color: Theme.of(context).colorScheme.primary),
              tooltip: 'Preview',
              onPressed: onPreview,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDocHint extends StatelessWidget {
  final String label;
  const _EmptyDocHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }
}
