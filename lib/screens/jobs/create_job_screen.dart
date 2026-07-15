import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/job_posting.dart';
import '../../models/teacher_profile.dart';
import '../../services/job_service.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final JobService _jobService = JobService();

  final _jobTitleController = TextEditingController();
  final _institutionNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _hoursController = TextEditingController();
  final _salaryController = TextEditingController();

  final List<AvailabilityShift> _selectedShifts = [];
  final List<TeachingLevel> _selectedLevels = [];
  final List<CertificationType> _selectedCertifications = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _institutionNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _hoursController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedShifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one shift')),
      );
      return;
    }

    if (_selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one level')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    try {
      JobPosting job = JobPosting(
        id: '',
        postedBy: user.uid,
        institutionName: _institutionNameController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        shifts: _selectedShifts,
        levels: _selectedLevels,
        requiredCertifications: _selectedCertifications,
        hoursPerWeek: _hoursController.text.isNotEmpty
            ? int.tryParse(_hoursController.text)
            : null,
        salaryRange: _salaryController.text.isNotEmpty
            ? _salaryController.text.trim()
            : null,
        postedAt: DateTime.now(),
        status: JobStatus.active,
      );

      await _jobService.createJobPosting(job);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create job: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _jobTitleController,
              decoration: const InputDecoration(labelText: 'Job Title *'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _institutionNameController,
              decoration: const InputDecoration(labelText: 'Institution Name *'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Job Description *'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location *'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Shifts
            const Text('Shifts *', style: TextStyle(fontWeight: FontWeight.bold)),
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

            // Levels
            const Text('Teaching Levels *', style: TextStyle(fontWeight: FontWeight.bold)),
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

            // Certifications
            const Text('Required Certifications', style: TextStyle(fontWeight: FontWeight.bold)),
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

            TextFormField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hours per Week'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _salaryController,
              decoration: const InputDecoration(labelText: 'Salary Range', hintText: 'e.g., \$1000-1500/month'),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isCreating ? null : _createJob,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post Job', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
