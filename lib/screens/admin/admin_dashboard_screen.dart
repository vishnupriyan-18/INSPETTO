import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().getEmployeesStream(),
      builder: (context, snap) {
        final employees = snap.data ?? [];
        final total = employees.length;
        final active = employees.where((e) => e.isActive).length;
        final inactive = total - active;
        final byRole = <String, int>{
          'hod': 0,
          'field_officer': 0,
          'collector': 0,
          'it_admin': 0,
        };
        for (var e in employees) {
          byRole[e.role] = (byRole[e.role] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${context.watch<AuthProvider>().currentUser?.name ?? "Admin"}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Tamil Nadu Government — INSPETTO',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              _statRow([
                _StatCard('Total Employees', '$total', Icons.people, Colors.blue),
                _StatCard('Active', '$active', Icons.check_circle, Colors.green),
                _StatCard('Inactive', '$inactive', Icons.cancel, Colors.red),
              ]),
              const SizedBox(height: 16),
              const Text('By Role',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _statRow([
                _StatCard('HODs', '${byRole['hod']}', Icons.supervisor_account, Colors.purple),
                _StatCard('Field Officers', '${byRole['field_officer']}', Icons.person_pin, Colors.orange),
              ]),
              const SizedBox(height: 16),
              _statRow([
                _StatCard('Collectors', '${byRole['collector']}', Icons.map, Colors.teal),
                _StatCard('IT Admins', '${byRole['it_admin']}', Icons.admin_panel_settings, Colors.grey),
              ]),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Colors.black)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(List<Widget> cards) => Row(
        children: cards.map((c) => Expanded(child: c)).toList(),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(6),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
