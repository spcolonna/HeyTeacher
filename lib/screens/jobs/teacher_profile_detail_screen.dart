import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../models/teacher_profile.dart';
import '../../models/institution_staff.dart';
import '../../services/job_service.dart';
import '../../services/staff_service.dart';
import '../../services/firestore_wrapper.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
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
    } catch (e) {
      print('🔥 Clearing error: $e');
    }
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
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Update'),
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
                    if (_profile!.workExperiences.isNotEmpty) ...[
                      _buildCvSection(
                        icon: Icons.work_history_outlined,
                        title: 'Work Experience',
                        child: _buildWorkExperienceTimeline(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_profile!.skills.isNotEmpty) ...[
                      _buildCvSection(
                        icon: Icons.star_outline,
                        title: 'Skills',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _profile!.skills.map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(s, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                          )).toList(),
                        ),
                      ),
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
                    const SizedBox(height: 16),
                    _buildClearingSection(),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      child: Row(children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(child: Text("This teacher hasn't completed their profile yet.",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
        gradient: Theme.of(context).extension<AppDecor>()!.primaryGradient,
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
            child: AppAvatar(
              url: photoUrl,
              name: app.teacherName,
              radius: 36,
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
              Text(widget.application.institutionName, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCertChips() {
    if (_profile!.certifications.isEmpty) {
      return Text('No certifications listed', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13));
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
          Text('Availability', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
          Text('Teaching Levels', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

  Widget _buildWorkExperienceTimeline() {
    final experiences = _profile!.workExperiences;
    return Column(
      children: experiences.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        final isLast = i == experiences.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: exp.isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exp.role,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(exp.institutionName,
                                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          if (exp.isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('Current',
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(exp.dateRange,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        if (exp.duration.isNotEmpty) ...[
                          Text(' · ', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          Text(exp.duration, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ]),
                      if (exp.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(exp.description!,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    return _buildCvSection(
      icon: Icons.verified_outlined,
      title: 'Clearing',
      child: _clearing.isEmpty
          ? Row(children: [
              Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'No employment history yet',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 28),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        (_clearing.fold<double>(0, (s, e) => s + e.removalRating!) / _clearing.length)
                            .toStringAsFixed(1),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_clearing.length} evaluation${_clearing.length == 1 ? '' : 's'} from past employers',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ]),
                    const Spacer(),
                    Row(
                      children: List.generate(5, (i) {
                        final avg = _clearing.fold<double>(0, (s, e) => s + e.removalRating!) / _clearing.length;
                        return Icon(
                          i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 16,
                          color: Colors.amber.shade600,
                        );
                      }),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                // Individual entries
                ..._clearing.map((entry) => _buildClearingEntry(entry)),
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

  Widget _buildClearingEntry(InstitutionStaff entry) {
    final rating = entry.removalRating ?? 0;
    final color = rating >= 4 ? Colors.green : rating >= 3 ? Colors.orange : Colors.red;
    final date = entry.removedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.institutionName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  if (date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatClearingDate(date),
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ]),
              ),
              const SizedBox(width: 8),
              // Star rating with colored background
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star_rounded, size: 13, color: color),
                  const SizedBox(width: 3),
                  Text('$rating / 5',
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
          // Stars row
          const SizedBox(height: 6),
          Row(children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: Colors.amber.shade600,
          ))),
          // Removal reason badge
          if (entry.removalReason?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.label_outline, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(entry.removalReason!,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            ]),
          ],
          // Comment
          if (entry.removalComment?.isNotEmpty == true) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(entry.removalComment!,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatClearingDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: child,
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
