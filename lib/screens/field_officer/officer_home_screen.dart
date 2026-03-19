// Shows list of tasks assigned to this officer
// Member 2 implements this
import 'package:flutter/material.dart';

class OfficerHomeScreen extends StatelessWidget {
  final String officerId;
  const OfficerHomeScreen({super.key, required this.officerId});

  @override
  Widget build(BuildContext context) {
    // TODO: fetch and show assigned tasks
    // Each task card shows: title, location, priority, deadline, status badge
    // Tap task -> TaskDetailScreen
    return const Scaffold(body: Center(child: Text('My Tasks')));
  }
}
