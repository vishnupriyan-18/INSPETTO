// HOD dashboard showing task counts by status
// Member 3 implements this
import 'package:flutter/material.dart';

class HodHomeScreen extends StatelessWidget {
  final String hodId;
  const HodHomeScreen({super.key, required this.hodId});

  @override
  Widget build(BuildContext context) {
    // TODO: show stat cards
    // Total tasks, Pending review, Approved, Rejected, Missed
    // Recent activity list
    return const Scaffold(body: Center(child: Text('HOD Home')));
  }
}
