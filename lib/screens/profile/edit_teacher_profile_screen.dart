import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/teacher_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_wrapper.dart';
import '../../services/storage_service.dart';
import 'manage_documents_screen.dart';

const _kMethodologies = [
  'Communicative',
  'Task-Based',
  'Grammar-Translation',
  'Content-Based',
  'TPR',
  'Blended Learning',
];

const _kSkillSuggestions = [
  'Lesson Planning',
  'Classroom Management',
  'ESL Teaching',
  'Grammar Instruction',
  'Pronunciation Training',
  'Business English',
  'Cambridge Exam Prep',
  'IELTS Preparation',
  'TOEFL Preparation',
  'Young Learners',
  'Adult Education',
  'Online Teaching',
];

class EditTeacherProfileScreen extends StatefulWidget {
  const EditTeacherProfileScreen({super.key});

  @override
  State<EditTeacherProfileScreen> createState() =>
      _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState extends State<EditTeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  TeacherProfile? _profile;
  File? _selectedImage;
  String? _photoUrl;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  List<CertificationType> _selectedCertifications = [];
  List<AvailabilityShift> _selectedShifts = [];
  List<TeachingLevel> _selectedLevels = [];
  List<String> _selectedMethodologies = [];
  List<String> _skills = [];
  List<WorkExperience> _workExperiences = [];
  bool _nativeSpeaker = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _yearsCtrl.dispose();
    _linkedinCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;
    try {
      final doc =
          await FirestoreWrapper.getDocument('teacher_profiles', user.uid);
      if (doc.exists) {
        _profile = TeacherProfile.fromFirestore(doc);
        _nameCtrl.text = _profile!.fullName;
        _phoneCtrl.text = _profile!.phone ?? '';
        _bioCtrl.text = _profile!.bio ?? '';
        _locationCtrl.text = _profile!.location ?? '';
        _yearsCtrl.text = _profile!.yearsOfExperience.toString();
        _linkedinCtrl.text = _profile!.linkedinUrl ?? '';
        _selectedCertifications = List.from(_profile!.certifications);
        _selectedShifts = List.from(_profile!.availability);
        _selectedLevels = List.from(_profile!.preferredLevels);
        _selectedMethodologies = List.from(_profile!.teachingMethodologies);
        _skills = List.from(_profile!.skills);
        _workExperiences = List.from(_profile!.workExperiences);
        _nativeSpeaker = _profile!.nativeSpeaker;
        _photoUrl = _profile!.photoUrl;
      } else {
        _nameCtrl.text = user.displayName;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _completeness {
    int score = 0;
    if (_photoUrl != null || _selectedImage != null) score += 15;
    if (_bioCtrl.text.trim().isNotEmpty) score += 10;
    if (_locationCtrl.text.trim().isNotEmpty) score += 10;
    if ((int.tryParse(_yearsCtrl.text) ?? 0) > 0) score += 5;
    if (_selectedCertifications.isNotEmpty) score += 10;
    if (_selectedShifts.isNotEmpty) score += 10;
    if (_selectedLevels.isNotEmpty) score += 10;
    if (_linkedinCtrl.text.trim().isNotEmpty) score += 5;
    if (_skills.isNotEmpty) score += 10;
    if (_workExperiences.isNotEmpty) score += 15;
    return score / 100;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final img = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (img != null) setState(() => _selectedImage = File(img.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
          ),
          if (_photoUrl != null || _selectedImage != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() { _selectedImage = null; _photoUrl = null; });
              },
            ),
        ]),
      ),
    );
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedImage == null) return _photoUrl;
    setState(() => _isUploadingPhoto = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) return null;
      return await _storageService.uploadProfilePhoto(
        file: _selectedImage!,
        userId: user.uid,
      );
    } catch (e) {
      return null;
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one availability shift')),
      );
      return;
    }
    if (_selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one teaching level')),
      );
      return;
    }

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final uploadedPhotoUrl = await _uploadPhoto();

      final updated = TeacherProfile(
        uid: user.uid,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        linkedinUrl: _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        nativeSpeaker: _nativeSpeaker,
        yearsOfExperience: int.tryParse(_yearsCtrl.text) ?? 0,
        certifications: _selectedCertifications,
        certificationFiles: _profile?.certificationFiles ?? [],
        certificationNames: _profile?.certificationNames ?? [],
        teachingMethodologies: _selectedMethodologies,
        availability: _selectedShifts,
        preferredLevels: _selectedLevels,
        skills: _skills,
        workExperiences: _workExperiences,
        cvUrl: _profile?.cvUrl,
        photoUrl: uploadedPhotoUrl,
        updatedAt: DateTime.now(),
      );

      await FirestoreWrapper.setDocument('teacher_profiles', user.uid, updated.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSkill(String s) {
    final trimmed = s.trim();
    if (trimmed.isNotEmpty && !_skills.contains(trimmed)) {
      setState(() { _skills.add(trimmed); });
    }
    _skillCtrl.clear();
  }

  Future<void> _showWorkExperienceDialog({WorkExperience? existing, int? index}) async {
    final instCtrl = TextEditingController(text: existing?.institutionName ?? '');
    final roleCtrl = TextEditingController(text: existing?.role ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final startYearCtrl = TextEditingController(
        text: existing != null ? existing.startYear.toString() : '');
    final endYearCtrl = TextEditingController(
        text: existing?.endYear?.toString() ?? '');

    int startMonth = existing?.startMonth ?? 1;
    int endMonth = existing?.endMonth ?? 1;
    bool isCurrent = existing?.isCurrent ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Add Experience' : 'Edit Experience'),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: instCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Institution / Company *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Role / Position *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. English Teacher',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  Text('Start date',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: startMonth,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(WorkExperience.monthNames[i]),
                        )),
                        onChanged: (v) => setS(() => startMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: startYearCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                          hintText: '2022',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I currently work here'),
                    value: isCurrent,
                    onChanged: (v) => setS(() => isCurrent = v),
                  ),
                  if (!isCurrent) ...[
                    Text('End date',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: endMonth,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          items: List.generate(12, (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(WorkExperience.monthNames[i]),
                          )),
                          onChanged: (v) => setS(() => endMonth = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: endYearCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                            hintText: '2024',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'What did you do? What levels did you teach?',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final inst = instCtrl.text.trim();
                final role = roleCtrl.text.trim();
                final startY = int.tryParse(startYearCtrl.text.trim());
                if (inst.isEmpty || role.isEmpty || startY == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please fill in institution, role, and start year')),
                  );
                  return;
                }
                final endY = isCurrent ? null : int.tryParse(endYearCtrl.text.trim());
                final entry = WorkExperience(
                  institutionName: inst,
                  role: role,
                  startYear: startY,
                  startMonth: startMonth,
                  endYear: endY,
                  endMonth: isCurrent ? null : endMonth,
                  isCurrent: isCurrent,
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                setState(() {
                  if (index != null) {
                    _workExperiences[index] = entry;
                  } else {
                    _workExperiences.insert(0, entry);
                  }
                  // Sort: current jobs first, then by start date descending
                  _workExperiences.sort((a, b) {
                    if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
                    final aKey = a.startYear * 12 + a.startMonth;
                    final bKey = b.startYear * 12 + b.startMonth;
                    return bKey.compareTo(aKey);
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final primary = Theme.of(context).colorScheme.primary;
    final busy = _isSaving || _isUploadingPhoto;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(onPressed: _saveProfile, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoSection(primary),
              const SizedBox(height: 16),
              _buildCompletenessBar(primary),
              const SizedBox(height: 24),
              _buildSection(
                icon: Icons.person_outline,
                title: 'Personal Information',
                child: _buildPersonalFields(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.notes,
                title: 'About Me',
                child: _buildBioField(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.work_history_outlined,
                title: 'Work Experience',
                child: _buildWorkExperienceSection(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.star_outline,
                title: 'Skills',
                child: _buildSkillsSection(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.workspace_premium_outlined,
                title: 'Certifications & Methodology',
                child: _buildCertificationsFields(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.schedule_outlined,
                title: 'Availability',
                child: _buildAvailabilityField(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.school_outlined,
                title: 'Teaching Levels',
                child: _buildLevelsField(),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.folder_outlined,
                title: 'Documents',
                child: _buildDocumentsButton(),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: busy ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(Color primary) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    border: Border.all(color: primary, width: 3),
                  ),
                  child: ClipOval(
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : _photoUrl != null
                            ? Image.network(_photoUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarPlaceholder())
                            : _avatarPlaceholder(),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showImageSourceSheet,
            child: Text(
              (_photoUrl != null || _selectedImage != null) ? 'Change photo' : 'Add photo',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessBar(Color primary) {
    final pct = (_completeness * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Profile completeness', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _completeness,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _completeness < 0.5 ? Colors.orange : _completeness < 0.8 ? Colors.amber : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
            hintText: '+598 XX XXX XXX',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _locationCtrl,
          decoration: const InputDecoration(
            labelText: 'Location',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
            hintText: 'e.g., Montevideo',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _yearsCtrl,
          decoration: const InputDecoration(
            labelText: 'Years of Experience *',
            prefixIcon: Icon(Icons.work_outline),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (int.tryParse(v) == null) return 'Enter a valid number';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _linkedinCtrl,
          decoration: InputDecoration(
            labelText: 'LinkedIn URL',
            prefixIcon: const Icon(Icons.link),
            border: const OutlineInputBorder(),
            hintText: 'https://linkedin.com/in/...',
            suffixIcon: _linkedinCtrl.text.trim().isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    onPressed: () async {
                      final url = Uri.tryParse(_linkedinCtrl.text.trim());
                      if (url != null) await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                  )
                : null,
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Native English speaker'),
          subtitle: Text(
            _nativeSpeaker ? 'Yes, English is my native language' : 'No, English is not my native language',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          value: _nativeSpeaker,
          onChanged: (v) => setState(() => _nativeSpeaker = v),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    final len = _bioCtrl.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: _bioCtrl,
          decoration: const InputDecoration(
            labelText: 'Professional summary',
            border: OutlineInputBorder(),
            hintText: 'Describe your teaching experience, style, and what makes you stand out...',
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          maxLength: 500,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Text('$len / 500', style: TextStyle(fontSize: 11, color: len > 450 ? Colors.orange : Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildWorkExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_workExperiences.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Add your teaching and work history',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ..._workExperiences.asMap().entries.map((entry) {
          final i = entry.key;
          final exp = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                title: Text(exp.role, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exp.institutionName, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(exp.dateRange, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _showWorkExperienceDialog(existing: exp, index: i),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                      onPressed: () => setState(() => _workExperiences.removeAt(i)),
                    ),
                  ],
                ),
                onTap: () => _showWorkExperienceDialog(existing: exp, index: i),
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => _showWorkExperienceDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Experience'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final suggestions = _kSkillSuggestions.where((s) => !_skills.contains(s)).take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_skills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((s) => Chip(
              label: Text(s, style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => setState(() => _skills.remove(s)),
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
            )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add a skill...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: _addSkill,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addSkill(_skillCtrl.text),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Suggestions:', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((s) => GestureDetector(
              onTap: () => setState(() { if (!_skills.contains(s)) _skills.add(s); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(s, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCertificationsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cambridge & International', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CertificationType.values.map((cert) {
            final selected = _selectedCertifications.contains(cert);
            return FilterChip(
              label: Text(cert.toString().split('.').last.toUpperCase()),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) { _selectedCertifications.add(cert); } else { _selectedCertifications.remove(cert); }
                });
              },
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Teaching Methodology', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kMethodologies.map((m) {
            final selected = _selectedMethodologies.contains(m);
            return FilterChip(
              label: Text(m),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) { _selectedMethodologies.add(m); } else { _selectedMethodologies.remove(m); }
                });
              },
              selectedColor: Colors.teal.withValues(alpha: 0.15),
              checkmarkColor: Colors.teal,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilityField() {
    const labels = {
      AvailabilityShift.morning: 'Morning',
      AvailabilityShift.afternoon: 'Afternoon',
      AvailabilityShift.evening: 'Evening',
    };
    const icons = {
      AvailabilityShift.morning: Icons.wb_sunny_outlined,
      AvailabilityShift.afternoon: Icons.wb_cloudy_outlined,
      AvailabilityShift.evening: Icons.nights_stay_outlined,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AvailabilityShift.values.map((shift) {
            final selected = _selectedShifts.contains(shift);
            return FilterChip(
              avatar: Icon(icons[shift], size: 16, color: selected ? Theme.of(context).colorScheme.primary : Colors.grey),
              label: Text(labels[shift]!),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) { _selectedShifts.add(shift); } else { _selectedShifts.remove(shift); }
                });
              },
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
        if (_selectedShifts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Select at least one shift', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildLevelsField() {
    const labels = {
      TeachingLevel.kinder: 'Kinder',
      TeachingLevel.primary: 'Primary',
      TeachingLevel.secondary: 'Secondary',
      TeachingLevel.adult: 'Adult',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TeachingLevel.values.map((level) {
            final selected = _selectedLevels.contains(level);
            return FilterChip(
              label: Text(labels[level]!),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) { _selectedLevels.add(level); } else { _selectedLevels.remove(level); }
                });
              },
              selectedColor: Colors.purple.withValues(alpha: 0.15),
              checkmarkColor: Colors.purple,
            );
          }).toList(),
        ),
        if (_selectedLevels.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Select at least one level', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildDocumentsButton() {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManageDocumentsScreen()),
      ),
      icon: const Icon(Icons.folder_open_outlined),
      label: const Text('Manage CV & Certifications'),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.outlineVariant,
      child: Icon(Icons.person, size: 54, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
