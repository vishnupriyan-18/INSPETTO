import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/status_badge.dart';
import 'submit_visit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;

  Future<void> _acceptTask() async {
    setState(() => _isLoading = true);
    try {
      final officerId = Provider.of<AuthProvider>(context, listen: false)
          .currentUser?.employeeId ?? '';
      await Provider.of<TaskProvider>(context, listen: false)
          .acceptTask(widget.task.id, officerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task accepted!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _confirmDeleteTask(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to completely delete this task? All associated visit reports and photos will also be permanently deleted from the database and Cloudinary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await FirestoreService().deleteTask(taskId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task and all data deleted successfully'), backgroundColor: Colors.red),
                  );
                  Navigator.pop(context); // close detail screen
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
              if (mounted) setState(() => _isLoading = false);
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final canAccept = t.status == 'assigned';
    final canSubmit = t.status == 'accepted' || t.status == 'inprogress' || t.status == 'rejected';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Task Details', style: TextStyle(color: Colors.white)),
        actions: [
          if (Provider.of<AuthProvider>(context).isHod || Provider.of<AuthProvider>(context).isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDeleteTask(context, t.id),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(t.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                StatusBadge(status: t.status),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.location_on, 'Location', t.location),
            _detailRow(Icons.description, 'Purpose', t.purpose),
            _detailRow(Icons.flag, 'Priority', t.priority.toUpperCase()),
            _detailRow(Icons.calendar_today, 'Deadline',
                '${t.deadline.day}/${t.deadline.month}/${t.deadline.year}'),
            _detailRow(Icons.person, 'Assigned By', t.createdBy),
            _detailRow(Icons.camera_alt, 'Total Visits', '${t.totalVisits}'),
            if (t.lastVisitAt != null)
              _detailRow(Icons.access_time, 'Last Visit At',
                  '${t.lastVisitAt!.day}/${t.lastVisitAt!.month}/${t.lastVisitAt!.year} ${t.lastVisitAt!.hour}:${t.lastVisitAt!.minute.toString().padLeft(2, '0')}'),
          ],
        ),
      ),
      bottomNavigationBar: (canAccept || canSubmit)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading
                        ? null
                        : canAccept
                            ? _acceptTask
                            : () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          SubmitVisitScreen(task: t)),
                                ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(canAccept ? 'Accept Task' : 'Submit Visit Report',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}