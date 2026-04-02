import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/notification_bell.dart';
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
        backgroundColor: Colors.black,
        title: const Text('INSPETTO Officer',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        actions: [
          const NotificationBell(iconColor: Colors.white),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false)
                  .logout(context);
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }
            },
          ),
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
