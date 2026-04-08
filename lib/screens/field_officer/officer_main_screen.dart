import 'package:flutter/material.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/profile_avatar_button.dart';
import 'officer_home_screen.dart';
import 'officer_history_screen.dart';

class OfficerMainScreen extends StatefulWidget {
  const OfficerMainScreen({super.key});

  @override
  State<OfficerMainScreen> createState() => _OfficerMainScreenState();
}

class _OfficerMainScreenState extends State<OfficerMainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const OfficerHomeScreen(),
      const OfficerHistoryScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
        ),
        backgroundColor: Colors.black,
        title: const Text('INSPETTO Officer',
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
              icon: Icon(Icons.task_outlined), label: 'My Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
