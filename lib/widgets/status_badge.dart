import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _fg(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Color _bg(String s) {
    switch (s) {
      case 'approved':
        return const Color(0xFFE8F5E9);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      case 'completed':
        return const Color(0xFFE3F2FD);
      case 'inprogress':
        return const Color(0xFFFFF3E0);
      case 'accepted':
        return const Color(0xFFF3E5F5);
      case 'missed':
        return const Color(0xFFFBE9E7);
      default:
        return const Color(0xFFF5F5F5); // pending / assigned
    }
  }

  Color _fg(String s) {
    switch (s) {
      case 'approved':
        return Colors.green[800]!;
      case 'rejected':
        return Colors.red[700]!;
      case 'completed':
        return Colors.blue[700]!;
      case 'inprogress':
        return Colors.orange[800]!;
      case 'accepted':
        return Colors.purple[700]!;
      case 'missed':
        return Colors.deepOrange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
