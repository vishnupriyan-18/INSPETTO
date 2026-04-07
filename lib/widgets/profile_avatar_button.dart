import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

/// Replaces the logout icon in all main screens.
/// Tapping opens a bottom sheet with profile info + logout.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  void _showProfileSheet(BuildContext context, UserModel user) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(
        user: user,
        onLogout: () async {
          Navigator.pop(context); // close sheet first
          await auth.logout(context);
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final initial =
        (user != null && user.name.isNotEmpty) ? user.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (user != null) _showProfileSheet(context, user);
        },
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white24,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const _ProfileSheet({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleDisplay(user.role);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.black,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            user.name,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 6),

          // Designation badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.designation.isNotEmpty ? user.designation : roleLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Employee ID chip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(Icons.badge_outlined, user.employeeId),
            ],
          ),
          const SizedBox(height: 8),

          // District + Department
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(Icons.location_on_outlined, user.district),
              const SizedBox(width: 8),
              _chip(Icons.business_outlined, user.department),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.grey.shade200),

          // Logout tile
          InkWell(
            onTap: onLogout,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Logout',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  String _roleDisplay(String role) {
    switch (role) {
      case 'it_admin':
        return 'IT Admin';
      case 'hod':
        return 'Head of Department';
      case 'field_officer':
        return 'Field Officer';
      case 'collector':
        return 'District Collector';
      default:
        return role;
    }
  }
}
