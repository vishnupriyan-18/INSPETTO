// Shows task status as a colored badge
// Used in all task list screens
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color getColor() {
    switch (status.toLowerCase()) {
      case 'assigned': return AppColors.assigned;
      case 'accepted': return AppColors.accepted;
      case 'inprogress': return AppColors.inProgress;
      case 'completed': return AppColors.completed;
      case 'approved': return AppColors.approved;
      case 'rejected': return AppColors.rejected;
      case 'missed': return AppColors.missed;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getColor()),
      ),
      child: Text(status, style: TextStyle(color: getColor(), fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
