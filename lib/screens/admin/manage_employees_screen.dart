import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/status_badge.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  String _filterRole = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'hod', 'field_officer', 'collector', 'it_admin']
                  .map((role) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(role == 'all' ? 'All' : role,
                              style: const TextStyle(fontSize: 12)),
                          selected: _filterRole == role,
                          onSelected: (_) =>
                              setState(() => _filterRole = role),
                          selectedColor: Colors.black,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                              color: _filterRole == role
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: FirestoreService().getEmployeesStream(
                role: _filterRole == 'all' ? null : _filterRole),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.black));
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const Center(
                    child: Text('No employees found',
                        style: TextStyle(color: Colors.grey)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _EmployeeCard(user: list[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final UserModel user;
  const _EmployeeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.black,
              child: Text(user.name.isNotEmpty ? user.name[0] : '?',
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${user.employeeId} | ${user.department}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(user.district,
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: user.role),
                const SizedBox(height: 6),
                Switch(
                  value: user.isActive,
                  activeColor: Colors.black,
                  onChanged: (v) async {
                    await FirestoreService()
                        .updateEmployeeStatus(user.employeeId, v);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            v ? '${user.name} activated' : '${user.name} deactivated'),
                        backgroundColor: v ? Colors.green : Colors.red,
                      ));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
