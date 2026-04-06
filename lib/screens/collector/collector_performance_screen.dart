import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class CollectorPerformanceScreen extends StatelessWidget {
  const CollectorPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final district = context.watch<AuthProvider>().currentUser?.district ?? '';
    debugPrint("Collector Performance (Filtering Field Officers) District: '$district'");

    // Step 1: Get all field officers in district
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService()
          .getEmployeesStream(role: 'field_officer')
          .map((list) {
            debugPrint("Total Field Officers in DB: ${list.length}");
            final filtered = list.where((u) => 
                u.district.trim().toLowerCase() == district.trim().toLowerCase()
            ).toList();
            debugPrint("Filtered Field Officers in '$district': ${filtered.length}");
            return filtered;
          }),
      builder: (ctx, officerSnap) {
        if (officerSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final officers = officerSnap.data ?? [];
        if (officers.isEmpty) {
          return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No field officers found in $district',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Check if officers have the correct district set.',
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: officers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final officer = officers[i];
            // Step 2: Get tasks for each officer
            return StreamBuilder<List<TaskModel>>(
              stream: FirestoreService().getTasksForOfficer(officer.employeeId),
              builder: (ctx, taskSnap) {
                final tasks = taskSnap.data ?? [];
                final total = tasks.length;
                final completed = tasks
                    .where((t) => t.status == 'completed' || t.status == 'approved')
                    .length;
                final missed = tasks.where((t) => t.status == 'missed').length;
                final pct = total > 0 ? (completed / total * 100) : 0.0;

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
                              child: Text(
                                  officer.name.isNotEmpty ? officer.name[0] : '?',
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(officer.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('${officer.employeeId} | ${officer.department}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: pct >= 75
                                            ? Colors.green
                                            : pct >= 50
                                                ? Colors.orange
                                                : Colors.red)),
                                const Text('Completion',
                                    style: TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _stat('Assigned', '$total', Colors.black),
                            _stat('Completed', '$completed', Colors.green),
                            _stat('Missed', '$missed', Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
