import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../auth/login_selection_screen.dart';
import '../admin/admin_main_screen.dart';
import '../hod/hod_main_screen.dart';
import '../field_officer/officer_main_screen.dart';
import '../collector/collector_main_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.restoreSession();
    if (mounted) setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const LoginSelectionScreen();
    return _routeForRole(user);
  }

  Widget _routeForRole(UserModel user) {
    switch (user.role) {
      case 'it_admin':
        return const AdminMainScreen();
      case 'hod':
        return const HodMainScreen();
      case 'field_officer':
        return const OfficerMainScreen();
      case 'collector':
        return const CollectorMainScreen();
      default:
        return const LoginSelectionScreen();
    }
  }
}
