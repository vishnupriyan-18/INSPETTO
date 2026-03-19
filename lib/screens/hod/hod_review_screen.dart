// HOD reviews submitted visit reports and approves or rejects
// Member 3 implements this - IMPORTANT SCREEN
import 'package:flutter/material.dart';

class HodReviewScreen extends StatelessWidget {
  final String taskId;
  const HodReviewScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    // TODO: show all visits submitted for this task
    // Show photo, GPS location, progress, remarks, signature
    // Approve button (green) and Reject button (red)
    // Rejection requires remarks input
    return const Scaffold(body: Center(child: Text('Review Task')));
  }
}
