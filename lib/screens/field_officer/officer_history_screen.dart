// Shows all past visits submitted by this officer
// Member 2 implements this
import 'package:flutter/material.dart';

class OfficerHistoryScreen extends StatelessWidget {
  final String officerId;
  const OfficerHistoryScreen({super.key, required this.officerId});

  @override
  Widget build(BuildContext context) {
    // TODO: fetch and show visit history
    // Filter chips: All, Approved, Rejected, Pending
    return const Scaffold(body: Center(child: Text('Visit History')));
  }
}
