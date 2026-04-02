import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';
import '../screens/field_officer/task_detail_screen.dart';
import '../screens/hod/hod_review_screen.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        context.read<AuthProvider>().currentUser?.employeeId ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: context
            .read<NotificationProvider>()
            .notificationsStream(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black));
          }
          final notifs = snap.data ?? [];
          if (notifs.isEmpty) {
            return const Center(
              child: Text('No notifications',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, i) {
              final n = notifs[i];
              return ListTile(
                tileColor: n.isRead ? Colors.white : const Color(0xFFF5F5F5),
                leading: Icon(_typeIcon(n.type),
                    color: _typeColor(n.type)),
                title: Text(n.title,
                    style: TextStyle(
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.bold)),
                subtitle: Text(n.message,
                    style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  _timeAgo(n.timestamp),
                  style:
                      const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                onTap: () async {
                  if (!n.isRead) {
                    context.read<NotificationProvider>().markRead(n.id);
                  }
                  if (n.taskId.isNotEmpty) {
                    final task = await FirestoreService().getTaskById(n.taskId);
                    if (task != null && context.mounted) {
                      final role = context.read<AuthProvider>().currentUser?.role;
                      if (role == 'field_officer') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                        );
                      } else if (role == 'hod') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HodReviewScreen(task: task)),
                        );
                      }
                    } else if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Task no longer exists or details unavailable.'))
                       );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment;
      case 'report_submitted':
        return Icons.upload_file;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'task_assigned':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
