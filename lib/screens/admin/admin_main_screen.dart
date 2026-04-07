import 'package:flutter/material.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/profile_avatar_button.dart';
import 'admin_dashboard_screen.dart';
import 'create_employee_screen.dart';
import 'manage_employees_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const AdminDashboardScreen(),
      const CreateEmployeeScreen(),
      const ManageEmployeesScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('INSPETTO Admin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        actions: [
          const NotificationBell(iconColor: Colors.white),
          const ProfileAvatarButton(),
        ],
      ),
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add_outlined), label: 'Add Employee'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined), label: 'Employees'),
        ],
      ),
    );
  }
}
