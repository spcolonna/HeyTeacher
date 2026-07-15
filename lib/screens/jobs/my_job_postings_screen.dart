import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/job_posting.dart';
import '../../services/job_service.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'applicants_screen.dart';
import 'create_job_screen.dart';

class MyJobPostingsScreen extends StatefulWidget {
  const MyJobPostingsScreen({super.key});

  @override
  State<MyJobPostingsScreen> createState() => _MyJobPostingsScreenState();
}

class _MyJobPostingsScreenState extends State<MyJobPostingsScreen> {
  final JobService _jobService = JobService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Job Postings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateJobScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<JobPosting>>(
        stream: _jobService.getJobsByInstitution(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList();
          }

          if (snapshot.hasError) {
            return ErrorState(onRetry: () => setState(() {}));
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return EmptyState(
              icon: Icons.work_outline,
              title: 'No job postings yet',
              message: 'Post your first job to reach qualified teachers.',
              ctaLabel: 'Post your first job',
              onCta: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateJobScreen()),
                );
              },
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
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _JobPostingCard(
                  job: job,
                  onViewApplicants: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplicantsScreen(job: job),
                      ),
                    );
                  },
                  onToggleStatus: () async {
                    final newStatus = job.status == JobStatus.active
                        ? JobStatus.closed
                        : JobStatus.active;
                    await _jobService.updateJobStatus(job.id, newStatus);
                  },
                  onDelete: () {
                    _showDeleteDialog(context, job, _jobService);
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

  void _showDeleteDialog(
      BuildContext context, JobPosting job, JobService jobService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Are you sure you want to delete "${job.jobTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await jobService.deleteJob(job.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _JobPostingCard extends StatelessWidget {
  final JobPosting job;
  final VoidCallback onViewApplicants;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _JobPostingCard({
    required this.job,
    required this.onViewApplicants,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = job.status == JobStatus.active;
    final scheme = Theme.of(context).colorScheme;
    final decor = Theme.of(context).extension<AppDecor>()!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.jobTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(
                label: isActive ? 'Active' : 'Closed',
                kind: isActive ? StatusKind.success : StatusKind.neutral,
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs + 2),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: Spacing.xs),
              Text(
                job.location,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: Spacing.lg),
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: Spacing.xs),
              Text(
                DateFormat('MMM dd, yyyy').format(job.postedAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewApplicants,
                  icon: const Icon(Icons.people_outline, size: 16),
                  label: Text(
                    '${job.applicationsCount} Applicant${job.applicationsCount != 1 ? 's' : ''}',
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              IconButton(
                icon: Icon(
                  isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: isActive ? decor.warning : decor.success,
                ),
                tooltip: isActive ? 'Close job' : 'Reopen job',
                onPressed: onToggleStatus,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: scheme.error),
                tooltip: 'Delete job',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
