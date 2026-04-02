import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/visit_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/status_badge.dart';

class OfficerHistoryScreen extends StatelessWidget {
  const OfficerHistoryScreen({super.key});

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
        final historyTasks = tasks
            .where((t) =>
                t.status == 'completed' ||
                t.status == 'approved' ||
                t.status == 'rejected')
            .toList();

        if (historyTasks.isEmpty) {
          return const Center(
              child: Text('No history found',
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: historyTasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _HistoryCard(task: historyTasks[i]),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TaskModel task;
  const _HistoryCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            StatusBadge(status: task.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
              '${task.location}\nCompleted on: ${task.lastVisitAt?.day ?? '-'}/${task.lastVisitAt?.month ?? '-'}/${task.lastVisitAt?.year ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        children: [
          StreamBuilder<List<VisitModel>>(
            stream: FirestoreService().getVisitsForTask(task.id),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }
              final visits = snap.data ?? [];
              if (visits.isEmpty) return const SizedBox.shrink();

              return Column(
                children: visits.map((v) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: v.photoUrl.isNotEmpty
                              ? Image.network(v.photoUrl,
                                  width: 60, height: 60, fit: BoxFit.cover)
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${v.progress}% Complete',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  const Spacer(),
                                  StatusBadge(status: v.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '${v.timestamp.day}/${v.timestamp.month}/${v.timestamp.year} ${v.timestamp.hour}:${v.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                              if (v.remarks.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(v.remarks,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                              if (v.rejectionReason.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Reason: ${v.rejectionReason}',
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 11)),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}