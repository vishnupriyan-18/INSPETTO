import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class HodOfficersScreen extends StatelessWidget {
  const HodOfficersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hodId = context.watch<AuthProvider>().currentUser?.employeeId ?? '';
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService()
          .getEmployeesStream(role: 'field_officer', hodId: hodId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        final officers = snap.data ?? [];
        if (officers.isEmpty) {
          return const Center(
              child: Text('No field officers assigned to you',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: officers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) =>
              _OfficerCard(officer: officers[i]),
        );
      },
    );
  }
}

class _OfficerCard extends StatelessWidget {
  final UserModel officer;
  const _OfficerCard({required this.officer});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: FirestoreService().getTasksForOfficer(officer.employeeId),
      builder: (ctx, snap) {
        final tasks = snap.data ?? [];
        final total = tasks.length;
        final completed = tasks
            .where((t) =>
                t.status == 'completed' || t.status == 'approved')
            .length;
        final pct =
            total > 0 ? (completed / total * 100).toStringAsFixed(0) : '—';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Text(officer.name.isNotEmpty ? officer.name[0] : '?',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(officer.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(officer.employeeId,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: officer.isActive
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          officer.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                              color: officer.isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stat('Tasks', '$total'),
                    _stat('Completed', '$completed'),
                    _stat('Completion %', '$pct%'),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.black,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
