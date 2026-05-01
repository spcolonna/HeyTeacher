import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../models/teacher_profile.dart';
import '../../models/institution_staff.dart';
import '../../services/job_service.dart';
import '../../services/staff_service.dart';
import '../../services/firestore_wrapper.dart';
import '../profile/document_preview_screen.dart';

class TeacherProfileDetailScreen extends StatefulWidget {
  final JobApplication application;

  const TeacherProfileDetailScreen({super.key, required this.application});

  @override
  State<TeacherProfileDetailScreen> createState() =>
      _TeacherProfileDetailScreenState();
}

class _TeacherProfileDetailScreenState
    extends State<TeacherProfileDetailScreen> {
  TeacherProfile? _profile;
  List<InstitutionStaff> _clearing = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
    _loadClearing();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final doc = await FirestoreWrapper.getDocument(
        'teacher_profiles',
        widget.application.teacherId,
      );
      if (doc.exists) {
        setState(() { _profile = TeacherProfile.fromFirestore(doc); _isLoading = false; });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClearing() async {
    try {
      final list = await StaffService().getTeacherClearing(widget.application.teacherId);
      if (mounted) setState(() => _clearing = list);
    } catch (_) {}
  }

  void _showUpdateStatusDialog(BuildContext context, JobService jobService) {
    ApplicationStatus selectedStatus = widget.application.status;
    final notesCtrl =
        TextEditingController(text: widget.application.institutionNotes);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Update Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...ApplicationStatus.values.map((s) => RadioListTile<ApplicationStatus>(
                    title: Text(s.toString().split('.').last),
                    value: s,
                    groupValue: selectedStatus,
                    onChanged: (v) => setS(() => selectedStatus = v!),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 8),
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note for this applicant...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await jobService.updateApplicationStatus(
                  applicationId: widget.application.id,
                  status: selectedStatus,
                  notes: notesCtrl.text.trim(),
                  teacherId: widget.application.teacherId,
                  jobTitle: widget.application.jobTitle,
                  institutionName: widget.application.institutionName,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Status updated'), backgroundColor: Colors.green),
                  );
                }
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
    final jobService = JobService();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.application.teacherName),
        actions: [
          TextButton.icon(
            onPressed: () => _showUpdateStatusDialog(context, jobService),
            icon: const Icon(Icons.edit, color: Colors.white, size: 18),
            label: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppliedForCard(),
                  if (_profile != null) ...[
                    const SizedBox(height: 20),
                    if (_profile!.bio != null) ...[
                      _buildCvSection(icon: Icons.notes, title: 'Professional Summary', child: Text(_profile!.bio!)),
                      const SizedBox(height: 16),
                    ],
                    _buildCvSection(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Certifications',
                      child: _buildCertChips(),
                    ),
                    const SizedBox(height: 16),
                    _buildCvSection(
                      icon: Icons.schedule_outlined,
                      title: 'Availability & Levels',
                      child: _buildAvailabilityAndLevels(),
                    ),
                    if (_profile!.teachingMethodologies.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildCvSection(
                        icon: Icons.psychology_outlined,
                        title: 'Teaching Methodology',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _profile!.teachingMethodologies
                              .map((m) => Chip(
                                    label: Text(m, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.teal.shade50,
                                    side: BorderSide(color: Colors.teal.shade200),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildDocumentsSection(),
                    if (_clearing.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildClearingSection(),
                    ],
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      child: Row(children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade500),
                        const SizedBox(width: 12),
                        Expanded(child: Text("This teacher hasn't completed their profile yet.",
                            style: TextStyle(color: Colors.grey.shade600))),
                      ]),
                    ),
                  ],
                  if (widget.application.institutionNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildCvSection(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'Your Notes',
                      child: Text(widget.application.institutionNotes!, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ],
                  if (widget.application.coverLetter?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildCvSection(
                      icon: Icons.description_outlined,
                      title: 'Cover Letter',
                      child: Text(widget.application.coverLetter!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showUpdateStatusDialog(context, jobService),
            icon: const Icon(Icons.update),
            label: const Text('Update Application Status'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final app = widget.application;
    final profile = _profile;
    final photoUrl = profile?.photoUrl ?? app.teacherPhotoUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              child: photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarLetter(),
                      ),
                    )
                  : _avatarLetter(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app.teacherName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: app.status),
                  ],
                ),
                const SizedBox(height: 3),
                if (app.teacherEmail != null)
                  Text(app.teacherEmail!, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (profile != null) ...[
                      if (profile.location != null)
                        _HeaderChip(icon: Icons.location_on, label: profile.location!),
                      _HeaderChip(icon: Icons.work_outline, label: '${profile.yearsOfExperience} yrs'),
                      if (profile.nativeSpeaker)
                        _HeaderChip(icon: Icons.record_voice_over, label: 'Native', color: Colors.green.shade300),
                    ],
                    if (profile?.linkedinUrl != null)
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.tryParse(profile!.linkedinUrl!);
                          if (url != null) await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        child: const _HeaderChip(icon: Icons.link, label: 'LinkedIn'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedForCard() {
    return _buildInfoCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.business_center_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.application.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(widget.application.institutionName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCertChips() {
    if (_profile!.certifications.isEmpty) {
      return Text('No certifications listed', style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
    }

    Color certColor(CertificationType c) {
      switch (c) {
        case CertificationType.fce:
        case CertificationType.cae:
        case CertificationType.cpe:
          return Colors.blue.shade600;
        case CertificationType.celta:
        case CertificationType.delta:
          return Colors.green.shade600;
        case CertificationType.tesol:
        case CertificationType.tefl:
          return Colors.orange.shade700;
        case CertificationType.other:
          return Colors.grey.shade600;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _profile!.certifications.map((cert) {
        final color = certColor(cert);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            cert.toString().split('.').last.toUpperCase(),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvailabilityAndLevels() {
    const shiftLabels = {
      AvailabilityShift.morning: 'Morning',
      AvailabilityShift.afternoon: 'Afternoon',
      AvailabilityShift.evening: 'Evening',
    };
    const levelLabels = {
      TeachingLevel.kinder: 'Kinder',
      TeachingLevel.primary: 'Primary',
      TeachingLevel.secondary: 'Secondary',
      TeachingLevel.adult: 'Adult',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_profile!.availability.isNotEmpty) ...[
          Text('Availability', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _profile!.availability.map((s) => Chip(
                  label: Text(shiftLabels[s]!, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide(color: Colors.green.shade200),
                )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (_profile!.preferredLevels.isNotEmpty) ...[
          Text('Teaching Levels', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _profile!.preferredLevels.map((l) => Chip(
                  label: Text(levelLabels[l]!, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.purple.shade50,
                  side: BorderSide(color: Colors.purple.shade200),
                )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentsSection() {
    final cvUrl = widget.application.cvUrl ?? _profile?.cvUrl;
    final certFiles = _profile?.certificationFiles ?? [];
    final certNames = _profile?.certificationNames ?? [];

    if (cvUrl == null && certFiles.isEmpty) return const SizedBox.shrink();

    return _buildCvSection(
      icon: Icons.attach_file,
      title: 'Documents',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cvUrl != null)
            _DocumentRow(
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red.shade700,
              label: 'Curriculum Vitae',
              onPreview: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(
                    url: cvUrl,
                    title: 'CV',
                    isImage: false,
                  ),
                ),
              ),
            ),
          if (cvUrl != null && certFiles.isNotEmpty) const SizedBox(height: 8),
          ...certFiles.asMap().entries.map((e) {
            final idx = e.key;
            final url = e.value;
            final name = (idx < certNames.length && certNames[idx].isNotEmpty)
                ? certNames[idx]
                : 'Certification ${idx + 1}';
            final isImage = DocumentPreviewScreen.urlIsImage(url);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DocumentRow(
                icon: isImage ? Icons.image : Icons.picture_as_pdf,
                iconColor: isImage ? Colors.blue.shade600 : Colors.red.shade700,
                label: name,
                onPreview: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentPreviewScreen(
                      url: url,
                      title: name,
                      isImage: isImage,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildClearingSection() {
    final avg = _clearing.fold<double>(0, (sum, e) => sum + e.removalRating!) / _clearing.length;
    final shown = _clearing.take(3).toList();

    return _buildCvSection(
      icon: Icons.verified_outlined,
      title: 'Clearing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 20),
            const SizedBox(width: 4),
            Text(
              avg.toStringAsFixed(1),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text(
              '${_clearing.length} evaluation${_clearing.length == 1 ? '' : 's'} from past employers',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ]),
          const SizedBox(height: 12),
          ...shown.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(entry.institutionName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      if (entry.removalComment?.isNotEmpty == true)
                        Text(entry.removalComment!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) => Icon(
                      i < (entry.removalRating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 14,
                      color: Colors.amber.shade600,
                    )),
                  ),
                ]),
              )),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.verified, size: 13, color: Colors.teal.shade600),
            const SizedBox(width: 4),
            Text('Verified by HeyTeacher',
                style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  Widget _buildCvSection({required IconData icon, required String title, required Widget child}) {
    return _buildInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _avatarLetter() {
    return Text(
      widget.application.teacherName.isNotEmpty
          ? widget.application.teacherName[0].toUpperCase()
          : 'T',
      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPreview;

  const _DocumentRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        TextButton.icon(
          onPressed: onPreview,
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('Preview', style: TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _HeaderChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 11),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case ApplicationStatus.pending: return Colors.orange;
      case ApplicationStatus.reviewed: return Colors.blue;
      case ApplicationStatus.accepted: return Colors.green;
      case ApplicationStatus.rejected: return Colors.red;
    }
  }

  String get _label {
    switch (status) {
      case ApplicationStatus.pending: return 'Pending';
      case ApplicationStatus.reviewed: return 'Reviewed';
      case ApplicationStatus.accepted: return 'Accepted';
      case ApplicationStatus.rejected: return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color),
      ),
      child: Text(_label, style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
