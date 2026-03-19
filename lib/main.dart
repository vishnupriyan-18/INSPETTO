import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inspetto/firebase_options.dart';
import 'package:inspetto/screens/auth/login_selection_screen.dart';
import 'package:inspetto/providers/auth_provider.dart';
import 'package:inspetto/providers/task_provider.dart';
import 'package:inspetto/providers/visit_provider.dart';
import 'package:inspetto/providers/location_provider.dart';
import 'package:inspetto/themes/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => VisitProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: const LoginSelectionScreen(),
    );
  }
}
