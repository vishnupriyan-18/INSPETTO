import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inspetto/firebase_options.dart';
import 'package:inspetto/screens/auth/auth_wrapper.dart';
import 'package:inspetto/providers/auth_provider.dart';
import 'package:inspetto/providers/task_provider.dart';
import 'package:inspetto/providers/visit_provider.dart';
import 'package:inspetto/providers/location_provider.dart';
import 'package:inspetto/providers/notification_provider.dart';
import 'package:inspetto/services/notification_service.dart';
import 'package:inspetto/themes/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  await _injectInitialData(); // Auto-create IT001 and COL001
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => VisitProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _injectInitialData() async {
  try {
    final db = FirebaseFirestore.instance;
    await db.collection('employees').doc('IT001').set({
      'employeeId': 'IT001',
      'name': 'System Admin',
      'phone': '+910000000000',
      'role': 'it_admin',
      'department': 'All',
      'district': 'All',
      'isActive': true,
    }, SetOptions(merge: true));
    await db.collection('employees').doc('COL001').set({
      'employeeId': 'COL001',
      'name': 'District Collector',
      'phone': '8667337744',
      'role': 'collector',
      'department': 'All',
      'district': 'Coimbatore',
      'isActive': true,
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('Injection failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INSPETTO',
      theme: lightTheme,
      home: const AuthWrapper(),
    );
  }
}
