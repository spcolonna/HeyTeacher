import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/institution_staff.dart';
import '../../providers/auth_provider.dart';
import '../../services/staff_service.dart';

class MyInstitutionsScreen extends StatelessWidget {
  const MyInstitutionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        Provider.of<AuthProvider>(context, listen: false).currentUser!;
    final service = StaffService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Institutions')),
      body: StreamBuilder<List<InstitutionStaff>>(
        stream: service.getInstitutionsForTeacher(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          final pending =
              all.where((s) => s.status == StaffStatus.pending).toList();
          final active =
              all.where((s) => s.status == StaffStatus.accepted).toList();
          final history = all
              .where((s) =>
                  s.status == StaffStatus.rejected ||
                  s.status == StaffStatus.removed)
              .toList();

          if (all.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apartment_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No institution associations yet',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Text(
                    'Institutions will send you requests to join their staff',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader('Pending Requests', Colors.orange),
                ...pending.map((s) => _PendingCard(
                      staff: s,
                      onAccept: () =>
                          service.respondToRequest(s.id, true),
                      onReject: () =>
                          service.respondToRequest(s.id, false),
                    )),
                const SizedBox(height: 16),
              ],
              if (active.isNotEmpty) ...[
                _sectionHeader('Active', Colors.green),
                ...active.map((s) => _ActiveCard(staff: s)),
                const SizedBox(height: 16),
              ],
              if (history.isNotEmpty) ...[
                _sectionHeader('History', Colors.grey),
                ...history.map((s) => _HistoryCard(staff: s)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 4, height: 18,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _PendingCard extends StatefulWidget {
  final InstitutionStaff staff;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingCard(
      {required this.staff,
      required this.onAccept,
      required this.onReject});

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  bool _loading = false;

  Future<void> _handle(bool accept) async {
    setState(() => _loading = true);
    if (accept) {
      widget.onAccept();
    } else {
      widget.onReject();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _institutionIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.staff.institutionName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Wants you to join their staff',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: const Text('Pending',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => _handle(false),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red)),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : () => _handle(true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Accept'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final InstitutionStaff staff;
  const _ActiveCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _institutionIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.institutionName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.check_circle,
                          size: 13, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text('Active staff member',
                          style: TextStyle(
                              fontSize: 12, color: Colors.green.shade700)),
                    ]),
                  ]),
            ),
          ]),
          if (staff.levels.isNotEmpty) ...[
            const SizedBox(height: 10),
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

class _HistoryCard extends StatelessWidget {
  final InstitutionStaff staff;
  const _HistoryCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    final isRemoved = staff.status == StaffStatus.removed;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          _institutionIcon(muted: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.institutionName,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(
                    isRemoved ? 'Past employment' : 'Request declined',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}

Widget _institutionIcon({bool muted = false}) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: muted ? Colors.grey.shade200 : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(Icons.apartment,
        color: muted ? Colors.grey.shade400 : Colors.blue.shade600,
        size: 24),
  );
}
