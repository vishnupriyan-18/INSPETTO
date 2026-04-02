import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class CollectorStatsScreen extends StatefulWidget {
  const CollectorStatsScreen({super.key});

  @override
  State<CollectorStatsScreen> createState() => _CollectorStatsScreenState();
}

class _CollectorStatsScreenState extends State<CollectorStatsScreen> {
  String _departmentFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AuthProvider>().currentUser;
    final district = appUser?.district ?? '';

    return StreamBuilder<List<TaskModel>>(
      stream: FirestoreService().getTasksByDistrict(district),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        var tasks = snap.data ?? [];
        if (_departmentFilter != 'All') {
          tasks = tasks.where((t) => t.department == _departmentFilter).toList();
        }

        final total = tasks.length;
        final completed = tasks
            .where((t) => t.status == 'completed' || t.status == 'approved')
            .length;
        final rejected = tasks.where((t) => t.status == 'rejected').length;
        final missed = tasks.where((t) => t.status == 'missed').length;
        final pending = total - completed - rejected - missed;

        final pct = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0';

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('District: $district',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    // Department Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All',
                          'TNRD',
                          'TWAD',
                          'Highways',
                          'Municipality',
                          'Corporation'
                        ].map((dept) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(dept,
                                      style: const TextStyle(fontSize: 12)),
                                  selected: _departmentFilter == dept,
                                  onSelected: (_) =>
                                      setState(() => _departmentFilter = dept),
                                  selectedColor: Colors.black,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                      color: _departmentFilter == dept
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Completion Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Overall Completion',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('$pct%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: total > 0 ? completed / total : 0,
                            backgroundColor: Colors.white24,
                            color: Colors.greenAccent,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Task Metrics',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatCard('Total Tasks', '$total', Colors.black),
                        _StatCard('Completed', '$completed', Colors.green),
                      ],
                    ),
                    Row(
                      children: [
                        _StatCard('Pending', '$pending', Colors.orange),
                        _StatCard('Rejected', '$rejected', Colors.red),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatCard('Delayed / Missed', '$missed', Colors.deepOrange),
                        const Expanded(child: SizedBox()), // empty slot
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
