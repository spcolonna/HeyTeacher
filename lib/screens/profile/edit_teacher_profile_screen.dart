import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/teacher_profile.dart';
import '../../services/firestore_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTeacherProfileScreen extends StatefulWidget {
  const EditTeacherProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditTeacherProfileScreen> createState() =>
      _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState extends State<EditTeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  TeacherProfile? _profile;

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
      } else {
        // Inicializar con datos del user
        _nameController.text = user.displayName;
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final profile = TeacherProfile(
        uid: user.uid,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        certifications: _selectedCertifications,
        availability: _selectedShifts,
        preferredLevels: _selectedLevels,
        yearsOfExperience: int.tryParse(_yearsController.text) ?? 0,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        updatedAt: DateTime.now(),
        certificationFiles: _profile?.certificationFiles ?? [],
        cvUrl: _profile?.cvUrl,
      );

      await FirestoreWrapper.setDocument(
          'teacher_profiles', user.uid, profile.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Save',
                    style: TextStyle(color: Colors.black, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Montevideo, Punta del Este',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Years of Experience',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Certifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: CertificationType.values.map((cert) {
                return FilterChip(
                  label: Text(cert.toString().split('.').last.toUpperCase()),
                  selected: _selectedCertifications.contains(cert),
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
            const Text('Availability',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AvailabilityShift.values.map((shift) {
                return FilterChip(
                  label: Text(shift.toString().split('.').last),
                  selected: _selectedShifts.contains(shift),
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
            const SizedBox(height: 24),
            const Text('Preferred Levels',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
