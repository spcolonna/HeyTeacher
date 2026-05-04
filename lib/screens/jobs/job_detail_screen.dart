import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_user.dart';
import '../../models/job_posting.dart';
import '../../services/job_service.dart';

class JobDetailScreen extends StatefulWidget {
  final JobPosting job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final JobService _jobService = JobService();
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _jobService.incrementJobViews(widget.job.id);
  }

  Future<void> _applyToJob() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isApplying = true);

    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('teacher_profiles')
          .doc(user.uid)
          .get();
      final photoUrl = profileDoc.exists
          ? (profileDoc.data() as Map<String, dynamic>)['photoUrl'] as String?
          : null;

      await _jobService.applyToJob(
        jobId: widget.job.id,
        jobTitle: widget.job.jobTitle,
        institutionName: widget.job.institutionName,
        institutionId: widget.job.postedBy,
        teacherId: user.uid,
        teacherName: user.displayName,
        teacherEmail: user.email,
        teacherPhotoUrl: photoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('Already applied')
              ? 'You have already applied to this job'
              : 'Failed to submit application'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isTeacher = user?.userType == UserType.teacher;

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.jobTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.job.institutionName,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        widget.job.location,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.job.description,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                      'Shifts',
                      widget.job.shifts
                          .map((s) => s.toString().split('.').last)
                          .join(', ')),
                  _buildDetailRow(
                      'Levels',
                      widget.job.levels
                          .map((l) => l.toString().split('.').last)
                          .join(', ')),
                  if (widget.job.hoursPerWeek != null)
                    _buildDetailRow(
                        'Hours per week', '${widget.job.hoursPerWeek}'),
                  if (widget.job.salaryRange != null)
                    _buildDetailRow('Salary Range', widget.job.salaryRange!),
                  if (widget.job.requiredCertifications.isNotEmpty)
                    _buildDetailRow(
                      'Required Certifications',
                      widget.job.requiredCertifications
                          .map(
                              (c) => c.toString().split('.').last.toUpperCase())
                          .join(', '),
                    ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Posted',
                    DateFormat('MMM dd, yyyy').format(widget.job.postedAt),
                  ),
                  if (widget.job.expiresAt != null)
                    _buildDetailRow(
                      'Expires',
                      DateFormat('MMM dd, yyyy').format(widget.job.expiresAt!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isTeacher && widget.job.status == JobStatus.active
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isApplying ? null : _applyToJob,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isApplying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Apply Now', style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
