import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/job_posting.dart';
import '../../models/job_application.dart';
import '../../services/job_service.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'teacher_profile_detail_screen.dart';

class ApplicantsScreen extends StatefulWidget {
  final JobPosting job;

  const ApplicantsScreen({super.key, required this.job});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final JobService _jobService = JobService();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.jobTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Text(
              '${widget.job.applicationsCount} applicant${widget.job.applicationsCount != 1 ? 's' : ''}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<JobApplication>>(
        stream: _jobService.getApplicationsForJob(widget.job.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList();
          }
          if (snapshot.hasError) {
            return ErrorState(onRetry: () => setState(() {}));
          }

          final applications = snapshot.data ?? [];

          if (applications.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No applicants yet',
              message:
                  'Teachers who apply to this job will appear here.',
            );
          }

          return RefreshIndicator.adaptive(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
                return _ApplicantCard(
                  application: app,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherProfileDetailScreen(application: app),
                      ),
                    );
                  },
                  onStatusChanged: (status, notes) async {
                    await _jobService.updateApplicationStatus(
                      applicationId: app.id,
                      status: status,
                      notes: notes,
                      teacherId: app.teacherId,
                      jobTitle: app.jobTitle,
                      institutionName: app.institutionName,
                    );
                  },
                )
                    .animate(delay: (40 * min(index, 10)).ms)
                    .fadeIn(duration: Motion.base, curve: Motion.curve)
                    .slideY(begin: 0.06, curve: Motion.curve);
              },
            ),
          );
        },
      ),
    );
  }
}

StatusKind statusKindFor(ApplicationStatus status) => switch (status) {
      ApplicationStatus.pending => StatusKind.warning,
      ApplicationStatus.reviewed => StatusKind.info,
      ApplicationStatus.accepted => StatusKind.success,
      ApplicationStatus.rejected => StatusKind.error,
    };

String statusLabelFor(ApplicationStatus status) => switch (status) {
      ApplicationStatus.pending => 'Pending',
      ApplicationStatus.reviewed => 'Reviewed',
      ApplicationStatus.accepted => 'Accepted',
      ApplicationStatus.rejected => 'Rejected',
    };

class _ApplicantCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;
  final Function(ApplicationStatus, String?) onStatusChanged;

  const _ApplicantCard({
    required this.application,
    required this.onTap,
    required this.onStatusChanged,
  });

  void _showUpdateStatusDialog(BuildContext context) {
    ApplicationStatus selectedStatus = application.status;
    final notesController =
        TextEditingController(text: application.institutionNotes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update ${application.teacherName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status:',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Spacing.sm),
              ...ApplicationStatus.values.map((status) {
                return RadioListTile<ApplicationStatus>(
                  title: Text(statusLabelFor(status)),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) =>
                      setState(() => selectedStatus = value!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: Spacing.sm),
              Text('Notes:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Spacing.xs),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onStatusChanged(selectedStatus, notesController.text.trim());
                Navigator.pop(context);
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                url: application.teacherPhotoUrl,
                name: application.teacherName,
                radius: 28,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.teacherName,
                      style: textTheme.titleSmall,
                    ),
                    if (application.teacherEmail != null)
                      Text(
                        application.teacherEmail!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              StatusChip(
                label: statusLabelFor(application.status),
                kind: statusKindFor(application.status),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: scheme.onSurfaceVariant),
              const SizedBox(width: Spacing.xs),
              Text(
                DateFormat('MMM dd, yyyy').format(application.appliedAt),
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                'Tap to see profile →',
                style: textTheme.bodySmall?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm + 2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showUpdateStatusDialog(context),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('Update Status'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
