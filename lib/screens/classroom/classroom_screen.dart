import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/class_group.dart';
import '../../services/classroom_service.dart';
import '../../widgets/widgets.dart';
import '../../services/google_calendar_service.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class ClassroomScreen extends StatelessWidget {
  const ClassroomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    if (user == null) return const SizedBox.shrink();

    final service = ClassroomService();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Classroom'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateGroupScreen(teacherId: user.uid),
          ),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _GoogleAccountBanner(),
          Expanded(
            child: StreamBuilder<List<ClassGroup>>(
              stream: service.getGroupsForTeacher(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SkeletonList();
                }
                if (snap.hasError) {
                  return const EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load your groups',
                    message: 'Please check your connection and try again.',
                  );
                }

                final groups = snap.data ?? [];

                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.school_outlined,
                    title: 'No groups yet',
                    message:
                        'Create your first group to manage students and schedule Google Meet sessions.',
                    ctaLabel: 'Create Group',
                    onCta: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateGroupScreen(teacherId: user.uid),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _GroupCard(
                    group: groups[i],
                    teacherId: user.uid,
                    service: service,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleAccountBanner extends StatefulWidget {
  @override
  State<_GoogleAccountBanner> createState() => _GoogleAccountBannerState();
}

class _GoogleAccountBannerState extends State<_GoogleAccountBanner> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    GoogleCalendarService.signInSilently().then((_) {
      if (mounted) setState(() => _checking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const SizedBox.shrink();

    final account = GoogleCalendarService.currentAccount;

    if (account != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Google connected · ${account.email}',
                style:
                    const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await GoogleCalendarService.signOut();
                if (mounted) setState(() {});
              },
              child: Text('Disconnect',
                  style: TextStyle(
                      fontSize: 12, color: Colors.red.shade400)),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        await GoogleCalendarService.signIn();
        if (mounted) setState(() {});
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_circle_outlined, size: 18),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Connect Google to create Meet links',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}


class _GroupCard extends StatelessWidget {
  final ClassGroup group;
  final String teacherId;
  final ClassroomService service;

  const _GroupCard({
    required this.group,
    required this.teacherId,
    required this.service,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text(
            'This will delete "${group.name}" and all its meetings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              service.deleteGroup(group.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(
              group: group,
              teacherId: teacherId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.group_outlined, color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.students.length} student${group.students.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    if (group.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        group.description!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.red),
                onPressed: () => _confirmDelete(context),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
