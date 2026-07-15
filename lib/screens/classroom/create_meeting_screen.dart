import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/class_group.dart';
import '../../services/google_calendar_service.dart';
import '../../services/classroom_service.dart';

class CreateMeetingScreen extends StatefulWidget {
  final String groupId;
  final String teacherId;
  final List<Student> students;

  const CreateMeetingScreen({
    super.key,
    required this.groupId,
    required this.teacherId,
    this.students = const [],
  });

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _service = ClassroomService();

  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  Duration _duration = const Duration(hours: 1);
  bool _creating = false;

  static const _durations = [
    (label: '30 min', value: Duration(minutes: 30)),
    (label: '1 hour', value: Duration(hours: 1)),
    (label: '1.5 hours', value: Duration(minutes: 90)),
    (label: '2 hours', value: Duration(hours: 2)),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year, date.month, date.day,
        _scheduledAt.hour, _scheduledAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year, _scheduledAt.month, _scheduledAt.day,
        time.hour, time.minute,
      );
    });
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);

    // Ensure Google signed in
    if (!GoogleCalendarService.isSignedIn) {
      final account = await GoogleCalendarService.signIn();
      if (account == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In required to create a Meet link')),
          );
        }
        setState(() => _creating = false);
        return;
      }
    }

    final attendeeEmails = widget.students
        .where((s) => s.email != null)
        .map((s) => s.email!)
        .toList();

    final result = await GoogleCalendarService.createMeeting(
      title: _titleCtrl.text.trim(),
      scheduledAt: _scheduledAt,
      duration: _duration,
      attendeeEmails: attendeeEmails,
    );

    if (!result.ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Unknown error')),
        );
      }
      setState(() => _creating = false);
      return;
    }

    final meeting = await _service.createMeeting(
      groupId: widget.groupId,
      teacherId: widget.teacherId,
      title: _titleCtrl.text.trim(),
      meetLink: result.meetLink!,
      calendarEventId: result.calendarEventId,
      scheduledAt: _scheduledAt,
    );

    if (mounted) Navigator.pop(context, meeting);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dateFmt = DateFormat('EEE, MMM d · HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('New Meeting')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Google account banner
            FutureBuilder(
              future: GoogleCalendarService.signInSilently(),
              builder: (context, snapshot) {
                final account = GoogleCalendarService.currentAccount;
                if (account != null) {
                  return _GoogleConnectedTile(email: account.email);
                }
                return _GoogleConnectBanner(
                  onTap: () async {
                    await GoogleCalendarService.signIn();
                    setState(() {});
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Meeting title *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Text('Date & Time',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('MMM d, yyyy').format(_scheduledAt)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(DateFormat('HH:mm').format(_scheduledAt)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Duration',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _durations.map((d) {
                final selected = _duration == d.value;
                return ChoiceChip(
                  label: Text(d.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _duration = d.value),
                  selectedColor: primary.withValues(alpha: 0.15),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Meeting: ${dateFmt.format(_scheduledAt)} — ${dateFmt.format(_scheduledAt.add(_duration)).split('·').last.trim()}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _creating ? null : _create,
                icon: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.videocam),
                label: Text(_creating
                    ? 'Creating Meet link...'
                    : 'Create Google Meet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleConnectedTile extends StatelessWidget {
  final String email;
  const _GoogleConnectedTile({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connected as $email',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleConnectBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleConnectBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap to connect your Google account',
                style: TextStyle(fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
