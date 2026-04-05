import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/status_badge.dart';
import 'hod_review_screen.dart';

class HodTasksScreen extends StatefulWidget {
  const HodTasksScreen({super.key});

  @override
  State<HodTasksScreen> createState() => _HodTasksScreenState();
}

class _HodTasksScreenState extends State<HodTasksScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final hodId = context.watch<AuthProvider>().currentUser?.employeeId ?? '';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'all', 'assigned', 'accepted', 'inprogress',
                'completed', 'approved', 'rejected', 'missed'
              ].map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s == 'all' ? 'All' : s,
                      style: const TextStyle(fontSize: 11)),
                  selected: _filter == s,
                  onSelected: (_) => setState(() => _filter = s),
                  selectedColor: Colors.black,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                      color: _filter == s ? Colors.white : Colors.black),
                ),
              )).toList(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TaskModel>>(
            stream: FirestoreService().getTasksForHod(hodId),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.black));
              }
              var tasks = snap.data ?? [];
              if (_filter != 'all') {
                tasks = tasks.where((t) => t.status == _filter).toList();
              }
              if (tasks.isEmpty) {
                return Center(
                    child: Text('No $_filter tasks',
                        style: const TextStyle(color: Colors.grey)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _TaskCard(task: tasks[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showFinalConfirmation(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text('Are you absolutely sure you want to PERMANENTLY delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().deleteTask(task.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted successfully'), backgroundColor: Colors.black),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
          MaterialPageRoute(builder: (_) => HodReviewScreen(task: task)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(task.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  StatusBadge(status: task.status),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _showDeleteConfirmation(context);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete Task', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(task.location,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(task.assignedTo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: priorityColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(task.priority,
                      style: TextStyle(color: priorityColor, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${task.totalVisits} visits',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
