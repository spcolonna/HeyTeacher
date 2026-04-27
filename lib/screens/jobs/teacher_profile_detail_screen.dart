import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_application.dart';
import '../../models/teacher_profile.dart';
import '../../services/job_service.dart';
import '../../services/firestore_wrapper.dart';

class TeacherProfileDetailScreen extends StatefulWidget {
  final JobApplication application;

  const TeacherProfileDetailScreen({Key? key, required this.application})
      : super(key: key);

  @override
  State<TeacherProfileDetailScreen> createState() =>
      _TeacherProfileDetailScreenState();
}

class _TeacherProfileDetailScreenState
    extends State<TeacherProfileDetailScreen> {
  TeacherProfile? _teacherProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      DocumentSnapshot doc = await FirestoreWrapper.getDocument(
        'teacher_profiles',
        widget.application.teacherId,
      );

      if (doc.exists) {
        setState(() {
          _teacherProfile = TeacherProfile.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading teacher profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPlaceholderAvatar() {
    return Text(
      widget.application.teacherName.isNotEmpty
          ? widget.application.teacherName[0].toUpperCase()
          : 'T',
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade700,
      ),
    );
  }

  String _getCertLabel(CertificationType cert) {
    return cert.toString().split('.').last.toUpperCase();
  }

  String _getShiftLabel(AvailabilityShift shift) {
    switch (shift) {
      case AvailabilityShift.morning:
        return 'Morning';
      case AvailabilityShift.afternoon:
        return 'Afternoon';
      case AvailabilityShift.evening:
        return 'Evening';
    }
  }

  String _getLevelLabel(TeachingLevel level) {
    switch (level) {
      case TeachingLevel.kinder:
        return 'Kinder';
      case TeachingLevel.primary:
        return 'Primary';
      case TeachingLevel.secondary:
        return 'Secondary';
      case TeachingLevel.adult:
        return 'Adult';
    }
  }

  void _showUpdateStatusDialog(BuildContext context, JobService jobService) {
    ApplicationStatus selectedStatus = widget.application.status;
    final notesController =
    TextEditingController(text: widget.application.institutionNotes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...ApplicationStatus.values.map((status) {
                return RadioListTile<ApplicationStatus>(
                  title: Text(status.toString().split('.').last),  // ← CORREGIDO
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
              const SizedBox(height: 8),
              const Text('Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note for this applicant...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await jobService.updateApplicationStatus(
                  applicationId: widget.application.id,
                  status: selectedStatus,
                  notes: notesController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status updated'),
                      backgroundColor: Colors.green,
                    ),
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
    final JobService jobService = JobService();

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            // Header con info básica y FOTO
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: widget.application.teacherPhotoUrl != null
                          ? ClipOval(
                        child: Image.network(
                          widget.application.teacherPhotoUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderAvatar();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.blue.shade700,
                              ),
                            );
                          },
                        ),
                      )
                          : _buildPlaceholderAvatar(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.application.teacherName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.application.teacherEmail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.application.teacherEmail!,
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _StatusBadge(status: widget.application.status),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aplicó para
                  _SectionTitle('Applied for'),
                  _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.application.jobTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.application.institutionName,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Perfil del teacher si existe
                  if (_teacherProfile != null) ...[
                    _SectionTitle('Profile Information'),
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_teacherProfile!.bio != null) ...[
                            Text(_teacherProfile!.bio!),
                            const SizedBox(height: 12),
                          ],
                          if (_teacherProfile!.location != null)
                            _InfoRow('Location', _teacherProfile!.location!),
                          _InfoRow('Experience',
                              '${_teacherProfile!.yearsOfExperience} years'),
                          if (_teacherProfile!.phone != null)
                            _InfoRow('Phone', _teacherProfile!.phone!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_teacherProfile!.certifications.isNotEmpty) ...[
                      _SectionTitle('Certifications'),
                      _InfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _teacherProfile!.certifications.map((cert) {
                            return Chip(
                              label: Text(_getCertLabel(cert)),
                              backgroundColor: Colors.blue.shade50,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_teacherProfile!.availability.isNotEmpty) ...[
                      _SectionTitle('Availability'),
                      _InfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _teacherProfile!.availability.map((shift) {
                            return Chip(
                              label: Text(_getShiftLabel(shift)),
                              backgroundColor: Colors.green.shade50,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_teacherProfile!.preferredLevels.isNotEmpty) ...[
                      _SectionTitle('Preferred Teaching Levels'),
                      _InfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                          _teacherProfile!.preferredLevels.map((level) {
                            return Chip(
                              label: Text(_getLevelLabel(level)),
                              backgroundColor: Colors.purple.shade50,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ] else ...[
                    _InfoCard(
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This teacher hasn\'t completed their profile yet.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Notas de la institución si las hay
                  if (widget.application.institutionNotes != null &&
                      widget.application.institutionNotes!.isNotEmpty) ...[
                    _SectionTitle('Your Notes'),
                    _InfoCard(
                      child: Text(
                        widget.application.institutionNotes!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Cover letter si la hay
                  if (widget.application.coverLetter != null &&
                      widget.application.coverLetter!.isNotEmpty) ...[
                    _SectionTitle('Cover Letter'),
                    _InfoCard(
                      child: Text(widget.application.coverLetter!),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // CV link si lo tiene
                  if (widget.application.cvUrl != null) ...[
                    _SectionTitle('CV'),
                    _InfoCard(
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('CV attached'),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('CV download coming soon')),
                              );
                            },
                            child: const Text('View'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.reviewed:
        return Colors.blue;
      case ApplicationStatus.accepted:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  String get _label {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.reviewed:
        return 'Reviewed';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}