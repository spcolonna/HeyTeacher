import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../models/teaching_material.dart';
import '../../models/teacher_profile.dart';
import '../../services/material_service.dart';
import '../../services/storage_service.dart';
import '../../theme/theme.dart';

class UploadMaterialScreen extends StatefulWidget {
  final String? institutionId;
  final String? institutionName;

  const UploadMaterialScreen({
    super.key,
    this.institutionId,
    this.institutionName,
  });

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();
  final StorageService _storageService = StorageService();

  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  MaterialCategory _selectedCategory = MaterialCategory.lessonPlan;
  final List<TeachingLevel> _selectedLevels = [];

  // Para móvil
  File? _selectedFile;
  // Para web
  Uint8List? _selectedFileBytes;
  String? _fileName;

  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (img == null) return;

      // Ensure the filename has a recognizable image extension — the
      // material detail screen infers "is this an image?" from it.
      String name = img.name;
      if (!RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false)
          .hasMatch(name)) {
        name = '$name.jpg';
      }

      if (kIsWeb) {
        final bytes = await img.readAsBytes();
        setState(() {
          _fileName = name;
          _selectedFileBytes = bytes;
          _selectedFile = null;
        });
      } else {
        setState(() {
          _fileName = name;
          _selectedFile = File(img.path);
          _selectedFileBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error picking image: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFileSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Browse Files'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'png'],
        withData: kIsWeb, // Solo cargar bytes en web
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
          if (kIsWeb) {
            _selectedFileBytes = result.files.single.bytes;
          } else {
            _selectedFile = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error picking file: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      String? fileUrl;
      if (_fileName != null) {
        fileUrl = await _storageService.uploadTeachingMaterial(
          file: _selectedFile,
          bytes: _selectedFileBytes,
          userId: user.uid,
          originalFileName: _fileName!,
        );
      }

      // Parse tags
      List<String> tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Create material
      final material = TeachingMaterial(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        suitableFor: _selectedLevels,
        fileUrl: fileUrl,
        uploadedBy: user.uid,
        uploaderName: user.displayName,
        uploadedAt: DateTime.now(),
        tags: tags,
        institutionId: widget.institutionId,
        institutionName: widget.institutionName,
      );

      await _materialService.uploadMaterial(material);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading material: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Material'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadMaterial,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Upload', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            const Text('Category *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: MaterialCategory.values.map((cat) {
                return ChoiceChip(
                  label: Text(_getCategoryLabel(cat)),
                  selected: _selectedCategory == cat,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Suitable for *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TeachingLevel.values.map((level) {
                return FilterChip(
                  label: Text(level.toString().split('.').last),
                  selected: _selectedLevels.contains(level),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedLevels.add(level);
                      } else {
                        _selectedLevels.remove(level);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)', hintText: 'e.g., grammar, vocabulary, games'),
            ),
            const SizedBox(height: 24),
            const Text('File *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showFileSourceSheet,
              icon: const Icon(Icons.attach_file),
              label: Text(_fileName ?? 'Select File'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: $_fileName',
                style: TextStyle(color: Theme.of(context).extension<AppDecor>()!.success, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(MaterialCategory cat) {
    switch (cat) {
      case MaterialCategory.lessonPlan:
        return 'Lesson Plan';
      case MaterialCategory.flashcard:
        return 'Flashcard';
      case MaterialCategory.icebreaker:
        return 'Icebreaker';
      case MaterialCategory.worksheet:
        return 'Worksheet';
      case MaterialCategory.digitalTool:
        return 'Digital Tool';
      case MaterialCategory.other:
        return 'Other';
    }
  }
}
