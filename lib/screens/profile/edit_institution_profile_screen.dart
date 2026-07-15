import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/institution_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_wrapper.dart';

const _kInstitutionTypes = [
  'Private school',
  'Public school',
  'Bilingual school',
  'Language institute',
  'University',
  'Tutoring center',
  'Other',
];

class EditInstitutionProfileScreen extends StatefulWidget {
  const EditInstitutionProfileScreen({super.key});

  @override
  State<EditInstitutionProfileScreen> createState() =>
      _EditInstitutionProfileScreenState();
}

class _EditInstitutionProfileScreenState
    extends State<EditInstitutionProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  InstitutionProfile? _profile;

  final _nameCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rutCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirestoreWrapper.getDocument('institution_profiles', user.uid);

      if (doc.exists) {
        _profile = InstitutionProfile.fromFirestore(doc);
        _nameCtrl.text = _profile!.institutionName;
        _rutCtrl.text = _profile!.rut ?? '';
        _descCtrl.text = _profile!.description ?? '';
        _addressCtrl.text = _profile!.address ?? '';
        _phoneCtrl.text = _profile!.phone ?? '';
        _websiteCtrl.text = _profile!.website ?? '';
        _contactNameCtrl.text = _profile!.contactPersonName ?? '';
        _contactEmailCtrl.text = _profile!.contactPersonEmail ?? '';
        _instagramCtrl.text = _profile!.instagramUrl ?? '';
        _facebookCtrl.text = _profile!.facebookUrl ?? '';
        _selectedType = _profile!.institutionType;
      } else {
        _nameCtrl.text = user.displayName;
        _contactEmailCtrl.text = user.email;
      }
    } catch (e) {
      // ignore
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
      String? _n(String v) => v.trim().isEmpty ? null : v.trim();

      final profile = InstitutionProfile(
        uid: user.uid,
        institutionName: _nameCtrl.text.trim(),
        rut: _n(_rutCtrl.text),
        institutionType: _selectedType,
        description: _n(_descCtrl.text),
        address: _n(_addressCtrl.text),
        phone: _n(_phoneCtrl.text),
        website: _n(_websiteCtrl.text),
        contactPersonName: _n(_contactNameCtrl.text),
        contactPersonEmail: _n(_contactEmailCtrl.text),
        instagramUrl: _n(_instagramCtrl.text),
        facebookUrl: _n(_facebookCtrl.text),
        logoUrl: _profile?.logoUrl,
        createdAt: _profile?.createdAt ?? DateTime.now(),
      );

      await FirestoreWrapper.setDocument(
          'institution_profiles', user.uid, profile.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Institution Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _buildSection(
              icon: Icons.apartment,
              title: 'Institution Information',
              children: [
                _field(
                  controller: _nameCtrl,
                  label: 'Institution Name *',
                  icon: Icons.business,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _rutCtrl,
                  label: 'RUT',
                  icon: Icons.badge_outlined,
                  hint: 'e.g. 21.234.567-8',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: _inputDecoration('Institution Type', Icons.school_outlined),
                  items: _kInstitutionTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.notes,
              title: 'About',
              children: [
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 600,
                  decoration: _inputDecoration(
                      'Description', Icons.description_outlined,
                      hint: 'Tell teachers about your institution…'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.location_on_outlined,
              title: 'Location & Contact',
              children: [
                _field(
                  controller: _addressCtrl,
                  label: 'Address',
                  icon: Icons.map_outlined,
                  hint: 'Street, city, department',
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _phoneCtrl,
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _websiteCtrl,
                  label: 'Website',
                  icon: Icons.language,
                  hint: 'https://…',
                  keyboardType: TextInputType.url,
                  suffix: _websiteCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          onPressed: () async {
                            final url = Uri.tryParse(_websiteCtrl.text.trim());
                            if (url != null) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.share_outlined,
              title: 'Social Media',
              children: [
                _field(
                  controller: _instagramCtrl,
                  label: 'Instagram',
                  icon: Icons.camera_alt_outlined,
                  hint: 'https://instagram.com/…',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _facebookCtrl,
                  label: 'Facebook',
                  icon: Icons.facebook_outlined,
                  hint: 'https://facebook.com/…',
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.person_outline,
              title: 'Contact Person',
              children: [
                _field(
                  controller: _contactNameCtrl,
                  label: 'Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _contactEmailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration(label, icon, hint: hint, suffix: suffix),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
