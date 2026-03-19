// Main screen for Collector with bottom navigation
// Member 4 implements this
import 'package:flutter/material.dart';

class CollectorMainScreen extends StatelessWidget {
  final String collectorId;
  final String collectorName;
  const CollectorMainScreen({super.key, required this.collectorId, required this.collectorName});

  @override
  Widget build(BuildContext context) {
    // TODO: bottom nav with Map Dashboard and Stats tabs
    return const Scaffold(body: Center(child: Text('Collector Dashboard')));
  }
}
