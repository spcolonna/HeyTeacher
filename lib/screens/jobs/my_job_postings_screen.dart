import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/job_posting.dart';
import '../../services/job_service.dart';
import 'applicants_screen.dart';
import 'create_job_screen.dart';

class MyJobPostingsScreen extends StatelessWidget {
  const MyJobPostingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final JobService jobService = JobService();

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
        stream: jobService.getJobsByInstitution(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No job postings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateJobScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Post your first job'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                  await jobService.updateJobStatus(job.id, newStatus);
                },
                onDelete: () {
                  _showDeleteDialog(context, job, jobService);
                },
              );
            },
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await jobService.deleteJob(job.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
    super.key,
    required this.job,
    required this.onViewApplicants,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = job.status == JobStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.jobTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Closed',
                    style: TextStyle(
                      color: isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(job.postedAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewApplicants,
                    icon: const Icon(Icons.people, size: 16),
                    label: Text(
                      '${job.applicationsCount} Applicant${job.applicationsCount != 1 ? 's' : ''}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    isActive ? Icons.pause_circle : Icons.play_circle,
                    color: isActive ? Colors.orange : Colors.green,
                  ),
                  tooltip: isActive ? 'Close job' : 'Reopen job',
                  onPressed: onToggleStatus,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete job',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
