import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/status_badge.dart';
import 'task_detail_screen.dart';

class OfficerHomeScreen extends StatelessWidget {
  const OfficerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final officerId =
        context.watch<AuthProvider>().currentUser?.employeeId ?? '';
    return StreamBuilder<List<TaskModel>>(
      stream: FirestoreService().getTasksForOfficer(officerId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        final tasks = snap.data ?? [];
        final active = tasks.where((t) =>
            t.status != 'approved' && t.status != 'rejected').toList();
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Task Assignments',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${active.length} active task(s)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 20),
                    // Quick stats
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('Total', '${tasks.length}', Colors.black),
                          _chip('Assigned',
                              '${tasks.where((t) => t.status == 'assigned').length}',
                              Colors.blue),
                          _chip('In Progress',
                              '${tasks.where((t) => t.status == 'inprogress').length}',
                              Colors.orange),
                          _chip('Approved',
                              '${tasks.where((t) => t.status == 'approved').length}',
                              Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('My Tasks',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (tasks.isEmpty)
              const SliverFillRemaining(
                child: Center(
                    child: Text('No tasks assigned',
                        style: TextStyle(color: Colors.grey))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TaskCard(task: tasks[i]),
                    ),
                    childCount: tasks.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    Color priorityColor = task.priority == 'high'
        ? Colors.red
        : task.priority == 'medium'
            ? Colors.orange
            : Colors.green;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: priorityColor, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(task.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  StatusBadge(status: task.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(task.location,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                    '${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.camera_alt_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${task.totalVisits} visits',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}