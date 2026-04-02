import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'notification_list_screen.dart';

class NotificationBell extends StatelessWidget {
  final Color iconColor;
  const NotificationBell({super.key, this.iconColor = Colors.black});

  @override
  Widget build(BuildContext context) {
    final userId =
        context.watch<AuthProvider>().currentUser?.employeeId ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream:
          context.read<NotificationProvider>().unreadCountStream(userId),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationListScreen(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
