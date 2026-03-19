// Main screen for HOD with bottom navigation
// Member 3 implements this
import 'package:flutter/material.dart';

class HodMainScreen extends StatelessWidget {
  final String hodId;
  final String hodName;
  const HodMainScreen({super.key, required this.hodId, required this.hodName});

  @override
  Widget build(BuildContext context) {
    // TODO: implement bottom nav with Dashboard, Tasks, Officers tabs
    return const Scaffold(body: Center(child: Text('HOD Dashboard')));
  }
}
