import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_application.dart';
import '../../theme/theme.dart';
import '../../models/job_posting.dart';
import '../../services/job_service.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final JobApplication application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Detail')),
      body: ListView(
        children: [
          _Header(application: application),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompetitionCard(jobId: application.jobId),
                const SizedBox(height: 20),
                _TimelineSection(application: application),
                const SizedBox(height: 20),
                if (application.coverLetter != null &&
                    application.coverLetter!.isNotEmpty) ...[
                  _Section(
                    title: 'Cover Letter',
                    icon: Icons.description_outlined,
                    child: _BodyText(application.coverLetter!),
                  ),
                  const SizedBox(height: 20),
                ],
                if (application.cvUrl != null) ...[
                  _Section(
                    title: 'CV',
                    icon: Icons.attach_file,
                    child: _LinkButton(
                      label: 'Open CV',
                      url: application.cvUrl!,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (application.institutionNotes != null &&
                    application.institutionNotes!.isNotEmpty) ...[
                  _Section(
                    title: 'Notes from Institution',
                    icon: Icons.comment_outlined,
                    child: _BodyText(application.institutionNotes!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final JobApplication application;
  const _Header({required this.application});

  static const _statusConfig = {
    ApplicationStatus.pending: (
      label: 'Pending',
      color: Color(0xFFF59E0B),
      icon: Icons.hourglass_empty_rounded,
    ),
    ApplicationStatus.reviewed: (
      label: 'Under Review',
      color: Color(0xFF3B82F6),
      icon: Icons.visibility_outlined,
    ),
    ApplicationStatus.accepted: (
      label: 'Accepted',
      color: Color(0xFF10B981),
      icon: Icons.check_circle_outline,
    ),
    ApplicationStatus.rejected: (
      label: 'Not Selected',
      color: Color(0xFFEF4444),
      icon: Icons.cancel_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig[application.status]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        gradient: Theme.of(context).extension<AppDecor>()!.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            application.jobTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            application.institutionName,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cfg.icon, color: Colors.white, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      cfg.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.calendar_today_outlined,
                  color: Colors.white60, size: 13),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy').format(application.appliedAt),
                style: const TextStyle(
                    color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Competition card ──────────────────────────────────────────────────────────

class _CompetitionCard extends StatelessWidget {
  final String jobId;
  const _CompetitionCard({required this.jobId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JobPosting?>(
      future: JobService().getJobById(jobId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final job = snap.data;
        if (job == null) return const SizedBox.shrink();


        final count = job.applicationsCount;
        final isActive = job.status == JobStatus.active;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).extension<AppDecor>()!.info.softFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Theme.of(context).extension<AppDecor>()!.info.softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<AppDecor>()!.info.softFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_outline,
                    color: Theme.of(context).extension<AppDecor>()!.info,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count ${count == 1 ? 'person has' : 'people have'} applied for this position',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).extension<AppDecor>()!.info,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive ? 'Position still open' : 'Position closed',
                      style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? Theme.of(context).extension<AppDecor>()!.success
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Timeline section ──────────────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  final JobApplication application;
  const _TimelineSection({required this.application});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(application.status);

    return _Section(
      title: 'Application Status',
      icon: Icons.timeline,
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.active
                          ? step.color
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                    child: Icon(
                      step.icon,
                      size: 15,
                      color: step.active ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      color: step.active && i < steps.length - 1
                          ? step.color.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontWeight: step.active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: step.active
                              ? Colors.black87
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      if (step.subtitle != null)
                        Text(
                          step.subtitle!,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  List<_Step> _buildSteps(ApplicationStatus status) {
    final submitted = _Step(
      label: 'Application Submitted',
      icon: Icons.send_outlined,
      color: const Color(0xFF3B82F6),
      active: true,
      subtitle: DateFormat('MMM d, yyyy · HH:mm').format(application.appliedAt),
    );

    final reviewed = _Step(
      label: 'Under Review',
      icon: Icons.visibility_outlined,
      color: const Color(0xFF8B5CF6),
      active: status == ApplicationStatus.reviewed ||
          status == ApplicationStatus.accepted ||
          status == ApplicationStatus.rejected,
    );

    if (status == ApplicationStatus.accepted) {
      return [
        submitted,
        reviewed,
        const _Step(
          label: 'Accepted',
          icon: Icons.check_circle_outline,
          color: Color(0xFF10B981),
          active: true,
          subtitle: 'Congratulations!',
        ),
      ];
    } else if (status == ApplicationStatus.rejected) {
      return [
        submitted,
        reviewed,
        const _Step(
          label: 'Not Selected',
          icon: Icons.cancel_outlined,
          color: Color(0xFFEF4444),
          active: true,
          subtitle: 'Keep applying — the right opportunity is out there.',
        ),
      ];
    }

    return [
      submitted,
      reviewed,
      const _Step(
        label: 'Decision',
        icon: Icons.flag_outlined,
        color: Colors.grey,
        active: false,
        subtitle: 'Awaiting institution response',
      ),
    ];
  }
}

class _Step {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final String? subtitle;

  const _Step({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    this.subtitle,
  });
}

// ── Shared section wrapper ────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 14, height: 1.5)),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  const _LinkButton({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(label),
    );
  }
}
