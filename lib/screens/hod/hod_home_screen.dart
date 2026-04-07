import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/status_badge.dart';
import 'hod_review_screen.dart';

class HodHomeScreen extends StatelessWidget {
  const HodHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hodId = context.watch<AuthProvider>().currentUser?.employeeId ?? '';
    return StreamBuilder<List<TaskModel>>(
      stream: FirestoreService().getTasksForHod(hodId),
      builder: (ctx, snap) {
        final tasks = snap.data ?? [];
        final total = tasks.length;
        final pending = tasks.where((t) => t.status == 'assigned' || t.status == 'accepted' || t.status == 'inprogress').length;
        final approved = tasks.where((t) => t.status == 'approved').length;
        final rejected = tasks.where((t) => t.status == 'rejected').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Departmental Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.watch<AuthProvider>().currentUser?.department ?? ''} — ${context.watch<AuthProvider>().currentUser?.district ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _StatCard('Total', '$total', Colors.black),
                  _StatCard('Pending', '$pending', Colors.orange),
                ],
              ),
              Row(
                children: [
                  _StatCard('Approved', '$approved', Colors.green),
                  _StatCard('Rejected', '$rejected', Colors.red),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pending Reviews',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (snap.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...tasks
                  .where((t) => t.status == 'inprogress')
                  .map((t) => _TaskTile(task: t))
                  .toList(),
              if (tasks.where((t) => t.status == 'inprogress').isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: Text('No pending reviews',
                          style: TextStyle(color: Colors.grey))),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(task.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${task.location} | ${task.assignedTo}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: StatusBadge(status: task.status),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HodReviewScreen(task: task)),
        ),
      ),
    );
  }
}
