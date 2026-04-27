import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../models/teacher_profile.dart';
import '../../services/firestore_wrapper.dart';
import '../../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_documents_screen.dart';

class EditTeacherProfileScreen extends StatefulWidget {
  const EditTeacherProfileScreen({super.key});

  @override
  State<EditTeacherProfileScreen> createState() =>
      _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState extends State<EditTeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  TeacherProfile? _profile;
  File? _selectedImage;
  String? _photoUrl;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _yearsController = TextEditingController();

  List<CertificationType> _selectedCertifications = [];
  List<AvailabilityShift> _selectedShifts = [];
  List<TeachingLevel> _selectedLevels = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot doc =
          await FirestoreWrapper.getDocument('teacher_profiles', user.uid);

      if (doc.exists) {
        _profile = TeacherProfile.fromFirestore(doc);
        _nameController.text = _profile!.fullName;
        _phoneController.text = _profile!.phone ?? '';
        _bioController.text = _profile!.bio ?? '';
        _locationController.text = _profile!.location ?? '';
        _yearsController.text = _profile!.yearsOfExperience.toString();
        _selectedCertifications = List.from(_profile!.certifications);
        _selectedShifts = List.from(_profile!.availability);
        _selectedLevels = List.from(_profile!.preferredLevels);
        _photoUrl = _profile!.photoUrl;
      } else {
        _nameController.text = user.displayName;
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_photoUrl != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _photoUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedImage == null) return _photoUrl;

    setState(() => _isUploadingPhoto = true);

    try {
      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) return null;

      String downloadUrl = await _storageService.uploadProfilePhoto(
        file: _selectedImage!,
        userId: user.uid,
      );

      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
      return null;
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload photo first if there's a new one
      String? uploadedPhotoUrl = await _uploadPhoto();

      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) return;

      int years = int.tryParse(_yearsController.text) ?? 0;

      final updatedProfile = TeacherProfile(
        uid: user.uid,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        yearsOfExperience: years,
        certifications: _selectedCertifications,
        certificationFiles: _profile?.certificationFiles ?? [],
        availability: _selectedShifts,
        preferredLevels: _selectedLevels,
        cvUrl: _profile?.cvUrl,
        photoUrl: uploadedPhotoUrl,
        updatedAt: DateTime.now(),
      );

      await FirestoreWrapper.setDocument(
        'teacher_profiles',
        user.uid,
        updatedProfile.toMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
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
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving || _isUploadingPhoto)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Section
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                              : _photoUrl != null
                                  ? Image.network(
                                      _photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return _buildPlaceholderAvatar();
                                      },
                                    )
                                  : _buildPlaceholderAvatar(),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(
                    (_photoUrl != null || _selectedImage != null)
                        ? 'Change photo'
                        : 'Add photo',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: '+598 XX XXX XXX',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Montevideo',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _yearsController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience *',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter years of experience';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about yourself...',
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              // Certifications Section
              _buildSectionTitle('Certifications'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CertificationType.values.map((cert) {
                  final isSelected = _selectedCertifications.contains(cert);
                  return FilterChip(
                    label: Text(cert.toString().split('.').last),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCertifications.add(cert);
                        } else {
                          _selectedCertifications.remove(cert);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Availability Section
              _buildSectionTitle('Availability *'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AvailabilityShift.values.map((shift) {
                  final isSelected = _selectedShifts.contains(shift);
                  return FilterChip(
                    label: Text(shift.toString().split('.').last),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedShifts.add(shift);
                        } else {
                          _selectedShifts.remove(shift);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              if (_selectedShifts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Please select at least one shift',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Teaching Levels Section
              _buildSectionTitle('Preferred Teaching Levels *'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TeachingLevel.values.map((level) {
                  final isSelected = _selectedLevels.contains(level);
                  return FilterChip(
                    label: Text(level.toString().split('.').last),
                    selected: isSelected,
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
              if (_selectedLevels.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Please select at least one level',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Documents Section
              _buildSectionTitle('Documents'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageDocumentsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.folder),
                label: const Text('Manage CV & Certifications'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button (duplicate at bottom for convenience)
              ElevatedButton(
                onPressed:
                    (_isSaving || _isUploadingPhoto) ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSaving || _isUploadingPhoto
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile',
                        style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.grey.shade600,
      ),
    );
  }
}
