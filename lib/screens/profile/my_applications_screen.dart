import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/job_application.dart';
import '../../services/job_service.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../jobs/applicants_screen.dart' show statusKindFor, statusLabelFor;
import 'application_detail_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  final String teacherId;
  const MyApplicationsScreen({super.key, required this.teacherId});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  ApplicationStatus? _filter;

  static const _tabs = [
    (label: 'All', value: null),
    (label: 'Pending', value: ApplicationStatus.pending),
    (label: 'Reviewed', value: ApplicationStatus.reviewed),
    (label: 'Accepted', value: ApplicationStatus.accepted),
    (label: 'Rejected', value: ApplicationStatus.rejected),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: StreamBuilder<List<JobApplication>>(
        stream: JobService().getApplicationsByTeacher(widget.teacherId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList();
          }
          if (snap.hasError) {
            return ErrorState(onRetry: () => setState(() {}));
          }

          final all = snap.data ?? [];
          // sort in Dart to avoid composite index requirement
          all.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

          final filtered = _filter == null
              ? all
              : all.where((a) => a.status == _filter).toList();

          return Column(
            children: [
              if (all.isNotEmpty) _SummaryBar(applications: all),
              _FilterChips(
                tabs: _tabs,
                selected: _filter,
                counts: {
                  for (final t in _tabs.skip(1))
                    t.value!: all
                        .where((a) => a.status == t.value)
                        .length,
                },
                onSelected: (v) => setState(() => _filter = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.inbox_outlined,
                        title: _filter != null
                            ? 'No applications with this status'
                            : 'No applications yet',
                        message: _filter != null
                            ? 'Try selecting a different filter.'
                            : 'Browse the Job Board and apply to positions that match your profile.',
                      )
                    : RefreshIndicator.adaptive(
                        onRefresh: () async {
                          setState(() {});
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _ApplicationCard(
                            application: filtered[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApplicationDetailScreen(
                                  application: filtered[i],
                                ),
                              ),
                            ),
                          )
                              .animate(delay: (40 * min(i, 10)).ms)
                              .fadeIn(
                                  duration: Motion.base, curve: Motion.curve)
                              .slideY(begin: 0.06, curve: Motion.curve),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<JobApplication> applications;
  const _SummaryBar({required this.applications});

  @override
  Widget build(BuildContext context) {
    final decor = Theme.of(context).extension<AppDecor>()!;
    final total = applications.length;
    final accepted =
        applications.where((a) => a.status == ApplicationStatus.accepted).length;
    final pending =
        applications.where((a) => a.status == ApplicationStatus.pending).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: decor.primaryGradient,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(value: '$total', label: 'Total'),
          _Divider(),
          _Stat(value: '$pending', label: 'Pending'),
          _Divider(),
          _Stat(value: '$accepted', label: 'Accepted'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 32, width: 1, color: Colors.white.withValues(alpha: 0.3));
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final List<({String label, ApplicationStatus? value})> tabs;
  final ApplicationStatus? selected;
  final Map<ApplicationStatus, int> counts;
  final void Function(ApplicationStatus?) onSelected;

  const _FilterChips({
    required this.tabs,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: tabs.map((t) {
          final isSelected = selected == t.value;
          final count = t.value == null ? null : counts[t.value];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(count != null && count > 0
                  ? '${t.label} ($count)'
                  : t.label),
              selected: isSelected,
              onSelected: (_) => onSelected(t.value),
              selectedColor: primary.withValues(alpha: 0.15),
              checkmarkColor: primary,
              labelStyle: TextStyle(
                color: isSelected ? primary : null,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Application card ──────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;
  const _ApplicationCard({required this.application, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = application.status;

    return AppCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
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
                    Text(
                      application.jobTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      application.institutionName,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              StatusChip(
                label: statusLabelFor(status),
                kind: statusKindFor(status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: scheme.onSurfaceVariant),
              const SizedBox(width: Spacing.xs),
              Text(
                'Applied ${DateFormat('MMM d, yyyy').format(application.appliedAt)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                'View details',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.primary),
              ),
              Icon(Icons.chevron_right, size: 16, color: scheme.primary),
            ],
          ),
          if (application.status == ApplicationStatus.accepted ||
              application.status == ApplicationStatus.rejected) ...[
            const SizedBox(height: 10),
            _StatusProgressBar(status: application.status),
          ],
        ],
      ),
    );
  }
}

// ── Status progress bar ───────────────────────────────────────────────────────

class _StatusProgressBar extends StatelessWidget {
  final ApplicationStatus status;
  const _StatusProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final decor = Theme.of(context).extension<AppDecor>()!;
    final isAccepted = status == ApplicationStatus.accepted;
    final color =
        isAccepted ? decor.success : Theme.of(context).colorScheme.error;
    final icon = isAccepted ? Icons.check_circle : Icons.cancel;
    final msg = isAccepted
        ? 'Congratulations! Your application was accepted.'
        : 'This application was not selected.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
