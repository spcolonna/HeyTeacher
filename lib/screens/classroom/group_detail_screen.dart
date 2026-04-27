import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/class_group.dart';
import '../../models/class_meeting.dart';
import '../../services/classroom_service.dart';
import 'create_group_screen.dart';
import 'create_meeting_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final ClassGroup group;
  final String teacherId;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.teacherId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late final ClassroomService _service;
  late final StreamSubscription<List<ClassMeeting>> _meetingsSub;
  List<ClassMeeting> _meetings = [];
  bool _loadingMeetings = true;

  @override
  void initState() {
    super.initState();
    _service = ClassroomService();
    _meetingsSub = _service
        .getMeetingsForGroup(widget.group.id)
        .listen(
          (meetings) {
            if (mounted) setState(() { _meetings = meetings; _loadingMeetings = false; });
          },
          onError: (_) {
            if (mounted) setState(() { _loadingMeetings = false; });
          },
        );
  }

  @override
  void dispose() {
    _meetingsSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final teacherId = widget.teacherId;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateGroupScreen(
                  teacherId: teacherId,
                  existing: group,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateMeetingScreen(
              groupId: group.id,
              teacherId: teacherId,
              students: group.students,
            ),
          ),
        ),
        icon: const Icon(Icons.videocam),
        label: const Text('New Meeting'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (group.description != null) ...[
            Text(
              group.description!,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
          ],

          // Students section
          _SectionHeader(
            title: 'Students',
            count: group.students.length,
          ),
          const SizedBox(height: 8),
          if (group.students.isEmpty)
            const _EmptyHint(text: 'No students in this group yet.')
          else
            ...group.students.map((s) => _StudentTile(student: s)),

          const SizedBox(height: 28),

          // Meetings section
          const _SectionHeader(title: 'Meetings'),
          const SizedBox(height: 8),
          if (_loadingMeetings)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_meetings.isEmpty)
            const _EmptyHint(
                text: 'No meetings yet. Tap "New Meeting" to create one.')
          else
            Column(
              children: _meetings
                  .map((m) => _MeetingCard(
                        meeting: m,
                        group: group,
                        onDelete: () => _service.deleteMeeting(m.id),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  const _StudentTile({required this.student});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(student.name),
        subtitle: student.email != null
            ? Text(student.email!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (student.email != null)
              IconButton(
                icon: const Icon(Icons.email_outlined, size: 20),
                onPressed: () =>
                    _launch('mailto:${student.email}'),
                tooltip: 'Send email',
              ),
            if (student.phone != null)
              IconButton(
                icon: const Icon(Icons.message_outlined, size: 20,
                    color: Color(0xFF25D366)),
                onPressed: () {
                  final phone =
                      student.phone!.replaceAll(RegExp(r'[^\d+]'), '');
                  _launch('https://wa.me/$phone');
                },
                tooltip: 'WhatsApp',
              ),
          ],
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final ClassMeeting meeting;
  final ClassGroup group;
  final VoidCallback onDelete;

  const _MeetingCard({
    required this.meeting,
    required this.group,
    required this.onDelete,
  });

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: meeting.meetLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _shareWhatsApp(String? phone) {
    final text = Uri.encodeComponent(
      '📚 *${meeting.title}*\n'
      '📅 ${DateFormat('EEE MMM d, HH:mm').format(meeting.scheduledAt)}\n'
      '🎥 Join: ${meeting.meetLink}',
    );
    final url = phone != null
        ? 'https://wa.me/${phone.replaceAll(RegExp(r'[^\d+]'), '')}?text=$text'
        : 'https://wa.me/?text=$text';
    _launch(url);
  }

  void _shareEmail(String? email, String? name) {
    final subject = Uri.encodeComponent(meeting.title);
    final body = Uri.encodeComponent(
      'Hi${name != null ? ' $name' : ''},\n\n'
      'You\'re invited to "${meeting.title}".\n'
      '📅 ${DateFormat('EEEE, MMMM d · HH:mm').format(meeting.scheduledAt)}\n'
      '🎥 Join here: ${meeting.meetLink}\n\n'
      'See you there!',
    );
    final to = email ?? '';
    _launch('mailto:$to?subject=$subject&body=$body');
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ShareSheet(
        meeting: meeting,
        group: group,
        onWhatsApp: _shareWhatsApp,
        onEmail: _shareEmail,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete meeting?'),
        content: Text('This will remove "${meeting.title}" permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isPast = meeting.scheduledAt.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meeting.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Past',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE MMM d · HH:mm').format(meeting.scheduledAt),
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Meet link chip
            GestureDetector(
              onTap: () => _launch(meeting.meetLink),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, size: 16, color: primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        meeting.meetLink,
                        style: TextStyle(
                            color: primary,
                            fontSize: 12,
                            decoration: TextDecoration.underline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ActionChip(
                  icon: Icons.copy_outlined,
                  label: 'Copy',
                  onTap: () => _copyLink(context),
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () => _showShareSheet(context),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final ClassMeeting meeting;
  final ClassGroup group;
  final void Function(String? phone) onWhatsApp;
  final void Function(String? email, String? name) onEmail;

  const _ShareSheet({
    required this.meeting,
    required this.group,
    required this.onWhatsApp,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final students =
        group.students.where((s) => s.email != null || s.phone != null).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share "${meeting.title}"',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Select a student or share to all',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          // Share to all buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onWhatsApp(null);
                  },
                  icon: const Icon(Icons.chat_outlined,
                      color: Color(0xFF25D366), size: 18),
                  label: const Text('All via WhatsApp'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onEmail(null, null);
                  },
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('All via Email'),
                ),
              ),
            ],
          ),
          if (students.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Or pick a student:',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final s = students[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                      child: Text(s.name[0].toUpperCase(),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12)),
                    ),
                    title: Text(s.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s.phone != null)
                          IconButton(
                            icon: const Icon(Icons.chat_outlined,
                                size: 20, color: Color(0xFF25D366)),
                            onPressed: () {
                              Navigator.pop(context);
                              onWhatsApp(s.phone);
                            },
                          ),
                        if (s.email != null)
                          IconButton(
                            icon: const Icon(Icons.email_outlined, size: 20),
                            onPressed: () {
                              Navigator.pop(context);
                              onEmail(s.email, s.name);
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
