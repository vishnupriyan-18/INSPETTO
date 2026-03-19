// Main screen for Field Officer with bottom navigation
// Member 2 implements this
import 'package:flutter/material.dart';

class OfficerMainScreen extends StatelessWidget {
  final String officerId;
  final String officerName;
  const OfficerMainScreen({super.key, required this.officerId, required this.officerName});

  @override
  Widget build(BuildContext context) {
    // TODO: implement bottom nav with Home and History tabs
    return const Scaffold(body: Center(child: Text('Officer Home')));
  }
}
