// HOD sees list of all field officers under them
// Member 3 implements this
import 'package:flutter/material.dart';

class HodOfficersScreen extends StatelessWidget {
  final String hodId;
  const HodOfficersScreen({super.key, required this.hodId});

  @override
  Widget build(BuildContext context) {
    // TODO: list all officers
    // Show each officer name, active tasks count, completed tasks count
    return const Scaffold(body: Center(child: Text('Field Officers')));
  }
}
