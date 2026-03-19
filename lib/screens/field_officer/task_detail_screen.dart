// Shows full task details and Accept button
// Member 2 implements this
import 'package:flutter/material.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    // TODO: show task details
    // Show Accept button if status is 'assigned'
    // Show Submit Visit button if status is 'accepted' or 'inprogress'
    // Show visit history for this task
    return const Scaffold(body: Center(child: Text('Task Detail')));
  }
}
