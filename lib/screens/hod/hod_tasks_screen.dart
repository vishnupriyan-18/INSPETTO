// HOD sees all tasks they created
// Member 3 implements this
import 'package:flutter/material.dart';

class HodTasksScreen extends StatelessWidget {
  final String hodId;
  const HodTasksScreen({super.key, required this.hodId});

  @override
  Widget build(BuildContext context) {
    // TODO: list all tasks created by this HOD
    // Filter by status
    // Tap task -> HodReviewScreen
    return const Scaffold(body: Center(child: Text('All Tasks')));
  }
}
