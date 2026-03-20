import 'package:flutter/material.dart';
import 'package:inspetto/screens/field_officer/officer_home_screen.dart';
import 'package:inspetto/screens/field_officer/officer_history_screen.dart';
import 'package:inspetto/themes/app_colors.dart';

class OfficerMainScreen extends StatefulWidget {
  final String officerId;
  final String officerName;
  const OfficerMainScreen({
    super.key,
    required this.officerId,
    required this.officerName,
  });

  @override
  State<OfficerMainScreen> createState() => _OfficerMainScreenState();
}

class _OfficerMainScreenState extends State<OfficerMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _selectedIndex == 0 ? 'My Tasks' : 'History',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Profile'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.person, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.officerName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.officerId,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? OfficerHomeScreen(officerId: widget.officerId)
          : OfficerHistoryScreen(officerId: widget.officerId),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'My Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
