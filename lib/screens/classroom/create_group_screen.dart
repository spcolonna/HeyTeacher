import 'package:flutter/material.dart';
import '../../models/class_group.dart';
import '../../services/classroom_service.dart';

class CreateGroupScreen extends StatefulWidget {
  final String teacherId;
  final ClassGroup? existing;

  const CreateGroupScreen({
    super.key,
    required this.teacherId,
    this.existing,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _service = ClassroomService();

  final List<_StudentEntry> _studentEntries = [];
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.existing!.name;
      _descCtrl.text = widget.existing!.description ?? '';
      for (final s in widget.existing!.students) {
        _studentEntries.add(_StudentEntry(
          name: TextEditingController(text: s.name),
          email: TextEditingController(text: s.email ?? ''),
          phone: TextEditingController(text: s.phone ?? ''),
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final e in _studentEntries) {
      e.dispose();
    }
    super.dispose();
  }

  void _addStudent() {
    setState(() {
      _studentEntries.add(_StudentEntry(
        name: TextEditingController(),
        email: TextEditingController(),
        phone: TextEditingController(),
      ));
    });
  }

  void _removeStudent(int index) {
    setState(() {
      _studentEntries[index].dispose();
      _studentEntries.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final students = _studentEntries
        .map((e) => Student(
              name: e.name.text.trim(),
              email: e.email.text.trim().isEmpty ? null : e.email.text.trim(),
              phone: e.phone.text.trim().isEmpty ? null : e.phone.text.trim(),
            ))
        .where((s) => s.name.isNotEmpty)
        .toList();

    try {
      if (_isEditing) {
        await _service.updateGroup(ClassGroup(
          id: widget.existing!.id,
          teacherId: widget.teacherId,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          students: students,
          createdAt: widget.existing!.createdAt,
        ));
      } else {
        await _service.createGroup(
          teacherId: widget.teacherId,
          name: _nameCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          students: students,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Group' : 'New Group'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: primary)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Group name *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Students',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addStudent,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_studentEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No students yet. Tap "Add" to add one.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ...List.generate(_studentEntries.length, (i) {
              final entry = _studentEntries[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: entry.name,
                              decoration: const InputDecoration(
                                labelText: 'Name *',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () => _removeStudent(i),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: entry.email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          isDense: true,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: entry.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp',
                          isDense: true,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                          hintText: '+598 9x xxx xxx',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StudentEntry {
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;

  _StudentEntry({
    required this.name,
    required this.email,
    required this.phone,
  });

  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
  }
}
