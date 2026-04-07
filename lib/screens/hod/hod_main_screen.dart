import 'package:flutter/material.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/profile_avatar_button.dart';
import 'hod_home_screen.dart';
import 'create_task_screen.dart';
import 'hod_tasks_screen.dart';
import 'hod_officers_screen.dart';

class HodMainScreen extends StatefulWidget {
  const HodMainScreen({super.key});

  @override
  State<HodMainScreen> createState() => _HodMainScreenState();
}

class _HodMainScreenState extends State<HodMainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HodHomeScreen(),
      const CreateTaskScreen(),
      const HodTasksScreen(),
      const HodOfficersScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('INSPETTO HOD',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
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
              icon: Icon(Icons.home_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_task), label: 'Create Task'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Officers'),
        ],
      ),
    );
  }
}
