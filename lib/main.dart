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
  NotificationService().initialize(); // Run async to prevent blocking launch
  _injectInitialData(); // Auto-create IT001 and COL001
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
      'designation': 'IT Administrator',
      'department': 'All',
      'district': 'All',
      'isActive': true,
    }, SetOptions(merge: true));
    await db.collection('employees').doc('COL001').set({
      'employeeId': 'COL001',
      'name': 'District Collector',
      'phone': '8667337744',
      'role': 'collector',
      'designation': 'District Collector',
      'department': 'All',
      'district': 'Coimbatore',
      'isActive': true,
    }, SetOptions(merge: true));

    // ─── ADDING COIMBATORE SAMPLE DATA ─────────────────────────
    // 1. HOD Coimbatore
    await db.collection('employees').doc('HOD001').set({
      'employeeId': 'HOD001',
      'name': 'HOD Coimbatore',
      'phone': '9999999999',
      'role': 'hod',
      'designation': 'Head of Department',
      'department': 'Highways',
      'district': 'Coimbatore',
      'isActive': true,
    }, SetOptions(merge: true));

    // 2. Field Officer Coimbatore
    await db.collection('employees').doc('FO001').set({
      'employeeId': 'FO001',
      'name': 'Officer Coimbatore',
      'phone': '8888888888',
      'role': 'field_officer',
      'designation': 'Field Officer',
      'department': 'Highways',
      'district': 'Coimbatore',
      'hodId': 'HOD001',
      'isActive': true,
    }, SetOptions(merge: true));

    // 3. Sample Task
    final taskRef = db.collection('tasks').doc('TASK001');
    final taskDoc = await taskRef.get();
    if (!taskDoc.exists) {
      await taskRef.set({
        'title': 'Bridge Inspection - Coimbatore',
        'location': 'Gandhipuram Flyover',
        'purpose': 'Routine structural check',
        'priority': 'high',
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'assignedTo': 'FO001',
        'createdBy': 'HOD001',
        'status': 'assigned',
        'department': 'Highways',
        'district': 'Coimbatore',
        'totalVisits': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
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
