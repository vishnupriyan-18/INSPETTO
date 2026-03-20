import 'package:flutter/material.dart';
import 'package:inspetto/themes/app_colors.dart';
import 'package:inspetto/screens/field_officer/submit_visit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return Colors.blue;
      case 'accepted': return Colors.orange;
      case 'inprogress': return Colors.amber;
      case 'completed': return Colors.purple;
      case 'approved': return AppColors.approved;
      case 'rejected': return AppColors.rejected;
      default: return Colors.grey;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return AppColors.rejected;
      case 'medium': return Colors.orange;
      case 'low': return AppColors.approved;
      default: return Colors.grey;
    }
  }

  void _acceptTask() async {
    // TODO: Update status in Firebase
    setState(() {
      widget.task['status'] = 'accepted';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task accepted successfully!'),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final status = task['status'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Task Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Status badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: getStatusColor(status)),
                ),
                child: Text(
                  capitalizeFirst(status),
                  style: TextStyle(
                    color: getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Task title
            Text(
              task['title'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _detailRow(
                    Icons.location_on_outlined,
                    'Location',
                    task['location'] ?? '',
                  ),
                  const Divider(height: 20),
                  _detailRow(
                    Icons.info_outline,
                    'Purpose',
                    task['purpose'] ?? '',
                  ),
                  const Divider(height: 20),
                  _detailRow(
                    Icons.flag_outlined,
                    'Priority',
                    capitalizeFirst(task['priority'] ?? ''),
                    valueColor: getPriorityColor(task['priority'] ?? ''),
                  ),
                  const Divider(height: 20),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Deadline',
                    task['deadline'] ?? '',
                  ),
                  const Divider(height: 20),
                  _detailRow(
                    Icons.person_outline,
                    'Assigned by',
                    task['assignedBy'] ?? 'HOD',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Accept button - show only if status is assigned
            if (status == 'assigned')
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _acceptTask,
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  label: const Text(
                    'Accept Task',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Submit visit button - show if accepted or inprogress
            if (status == 'accepted' || status == 'inprogress')
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubmitVisitScreen(
                          taskId: task['taskId'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_outlined,
                      color: Colors.white),
                  label: const Text(
                    'Submit Visit Report',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Approved message
            if (status == 'approved')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.approved.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.approved),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.approved),
                    SizedBox(width: 8),
                    Text(
                      'This task has been approved!',
                      style: TextStyle(
                        color: AppColors.approved,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Rejected message
            if (status == 'rejected')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.rejected.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.rejected),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, color: AppColors.rejected),
                    SizedBox(width: 8),
                    Text(
                      'Task rejected. Please revisit!',
                      style: TextStyle(
                        color: AppColors.rejected,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}