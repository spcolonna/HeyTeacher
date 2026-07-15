import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/institution_staff.dart';
import '../../models/teacher_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/staff_service.dart';
import '../../widgets/widgets.dart';

const _kDismissalReasons = [
  'End of contract',
  'Performance issues',
  'Staff reduction',
  'Teacher resignation',
  'Other',
];

class ManageStaffScreen extends StatelessWidget {
  const ManageStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        Provider.of<AuthProvider>(context, listen: false).currentUser!;
    final service = StaffService();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Staff')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeacherSheet(context, service, user.uid,
            user.displayName),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Teacher'),
      ),
      body: StreamBuilder<List<InstitutionStaff>>(
        stream: service.getStaffForInstitution(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList();
          }
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load your staff',
              message: 'Please check your connection and try again.',
            );
          }
          final all = snapshot.data ?? [];
          final pending =
              all.where((s) => s.status == StaffStatus.pending).toList();
          final active =
              all.where((s) => s.status == StaffStatus.accepted).toList();

          if (all.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No staff yet',
                      style: TextStyle(
                          fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('Tap "Add Teacher" to invite a teacher',
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader(context, 'Pending Requests', pending.length),
                ...pending.map((s) => _PendingCard(
                      staff: s,
                      onCancel: () => service.cancelRequest(s.id),
                    )),
                const SizedBox(height: 16),
              ],
              if (active.isNotEmpty) ...[
                _sectionHeader(context, 'Active Staff', active.length),
                ...active.map((s) => _ActiveCard(
                      staff: s,
                      onEditLevels: () =>
                          _showEditLevelsSheet(context, service, s),
                      onRemove: () =>
                          _showRemoveDialog(context, service, s),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  void _showAddTeacherSheet(BuildContext context, StaffService service,
      String institutionId, String institutionName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddTeacherSheet(
        institutionId: institutionId,
        institutionName: institutionName,
        service: service,
      ),
    );
  }

  void _showEditLevelsSheet(
      BuildContext context, StaffService service, InstitutionStaff staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _EditLevelsSheet(staff: staff, service: service),
    );
  }

  void _showRemoveDialog(
      BuildContext context, StaffService service, InstitutionStaff staff) {
    showDialog(
      context: context,
      builder: (_) => _RemoveDialog(staff: staff, service: service),
    );
  }
}

// ─── Cards ──────────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final InstitutionStaff staff;
  final VoidCallback onCancel;

  const _PendingCard({required this.staff, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          _avatar(staff),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(staff.teacherName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(staff.teacherEmail,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Text('Pending',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.orange)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            tooltip: 'Cancel request',
            onPressed: onCancel,
          ),
        ]),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final InstitutionStaff staff;
  final VoidCallback onEditLevels;
  final VoidCallback onRemove;

  const _ActiveCard(
      {required this.staff,
      required this.onEditLevels,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(staff),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.teacherName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(staff.teacherEmail,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ]),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit levels',
              onPressed: onEditLevels,
            ),
            IconButton(
              icon: const Icon(Icons.person_remove_outlined,
                  color: Colors.red, size: 20),
              tooltip: 'Remove',
              onPressed: onRemove,
            ),
          ]),
          if (staff.levels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: staff.levels
                  .map((l) => Chip(
                        label: Text(l,
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.purple.shade50,
                        side: BorderSide(color: Colors.purple.shade200),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ]),
      ),
    );
  }
}

Widget _avatar(InstitutionStaff staff) {
  return CircleAvatar(
    radius: 22,
    backgroundColor: Colors.blue.shade100,
    backgroundImage: staff.teacherPhotoUrl != null
        ? NetworkImage(staff.teacherPhotoUrl!)
        : null,
    child: staff.teacherPhotoUrl == null
        ? Text(
            staff.teacherName.isNotEmpty
                ? staff.teacherName[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: Colors.blue.shade700, fontWeight: FontWeight.bold),
          )
        : null,
  );
}

// ─── Bottom sheets & dialogs ─────────────────────────────────────────────────

class _AddTeacherSheet extends StatefulWidget {
  final String institutionId;
  final String institutionName;
  final StaffService service;

  const _AddTeacherSheet({
    required this.institutionId,
    required this.institutionName,
    required this.service,
  });

  @override
  State<_AddTeacherSheet> createState() => _AddTeacherSheetState();
}

class _AddTeacherSheetState extends State<_AddTeacherSheet> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() { _loading = true; _error = null; });

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final err = await widget.service.sendRequest(
      institutionId: widget.institutionId,
      institutionName: widget.institutionName,
      teacherEmail: email,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _error = err);
    } else {
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Request sent!'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Add Teacher',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Search by the email they used to register',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Teacher email',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _error,
          ),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _send,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Send Request',
                    style: TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

class _EditLevelsSheet extends StatefulWidget {
  final InstitutionStaff staff;
  final StaffService service;

  const _EditLevelsSheet({required this.staff, required this.service});

  @override
  State<_EditLevelsSheet> createState() => _EditLevelsSheetState();
}

class _EditLevelsSheetState extends State<_EditLevelsSheet> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.staff.levels);
  }

  @override
  Widget build(BuildContext context) {
    const levels = TeachingLevel.values;
    const labels = {
      TeachingLevel.kinder: 'Kinder',
      TeachingLevel.primary: 'Primary',
      TeachingLevel.secondary: 'Secondary',
      TeachingLevel.adult: 'Adult',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Levels — ${widget.staff.teacherName}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Select the levels this teacher covers',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: levels.map((l) {
            final name = l.toString().split('.').last;
            return FilterChip(
              label: Text(labels[l] ?? name),
              selected: _selected.contains(name),
              onSelected: (v) =>
                  setState(() => v ? _selected.add(name) : _selected.remove(name)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    await widget.service
                        .updateStaffLevels(widget.staff.id, _selected.toList());
                    if (mounted) nav.pop();
                  },
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

class _RemoveDialog extends StatefulWidget {
  final InstitutionStaff staff;
  final StaffService service;

  const _RemoveDialog({required this.staff, required this.service});

  @override
  State<_RemoveDialog> createState() => _RemoveDialogState();
}

class _RemoveDialogState extends State<_RemoveDialog> {
  int _rating = 5;
  String _reason = _kDismissalReasons.first;
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Remove ${widget.staff.teacherName}'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Before removing this teacher, please rate their performance and add any relevant comments.',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Rating',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButton<String>(
              value: _reason,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: _kDismissalReasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _reason = v!),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comments (optional)',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  final nav = Navigator.of(context);
                  await widget.service.removeStaff(
                    docId: widget.staff.id,
                    rating: _rating,
                    comment: _commentCtrl.text,
                    reason: _reason,
                  );
                  if (mounted) nav.pop();
                },
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Remove',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
