import 'package:flutter/material.dart';
import 'package:inspetto/themes/app_colors.dart';
import 'package:inspetto/screens/field_officer/task_detail_screen.dart';

class OfficerHomeScreen extends StatefulWidget {
  final String officerId;
  const OfficerHomeScreen({super.key, required this.officerId});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  // Dummy tasks for now
  final List<Map<String, dynamic>> _tasks = [
    {
      'taskId': 'TASK001',
      'title': 'Road Repair Inspection',
      'location': 'Anna Nagar, Chennai',
      'purpose': 'Check road repair progress',
      'priority': 'high',
      'deadline': '25 Mar 2025',
      'status': 'assigned',
    },
    {
      'taskId': 'TASK002',
      'title': 'Street Light Check',
      'location': 'T Nagar, Chennai',
      'purpose': 'Verify street light installation',
      'priority': 'medium',
      'deadline': '28 Mar 2025',
      'status': 'accepted',
    },
    {
      'taskId': 'TASK003',
      'title': 'Drainage Inspection',
      'location': 'Velachery, Chennai',
      'purpose': 'Inspect drainage blockage',
      'priority': 'low',
      'deadline': '30 Mar 2025',
      'status': 'inprogress',
    },
    {
      'taskId': 'TASK004',
      'title': 'Park Renovation Check',
      'location': 'Adyar, Chennai',
      'purpose': 'Monitor park renovation',
      'priority': 'medium',
      'deadline': '01 Apr 2025',
      'status': 'approved',
    },
  ];

  String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return AppColors.inProgress;
      case 'accepted': return Colors.blue;
      case 'inprogress': return Colors.orange;
      case 'completed': return Colors.amber;
      case 'approved': return AppColors.approved;
      case 'rejected': return AppColors.rejected;
      case 'missed': return AppColors.missed;
      default: return Colors.grey;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return AppColors.rejected;
      case 'medium': return Colors.orange;
      case 'low': return AppColors.approved;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () async {
        setState(() {});
      },
      child: _tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tasks assigned yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TaskDetailScreen(task: task),
    ),
  );
},
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and priority row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task['title'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: getPriorityColor(task['priority'])
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: getPriorityColor(task['priority']),
                                  ),
                                ),
                                child: Text(
                                  capitalizeFirst(task['priority']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: getPriorityColor(task['priority']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Location
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                task['location'],
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Purpose
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                task['purpose'],
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Deadline and status row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due: ${task['deadline']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getStatusColor(task['status'])
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: getStatusColor(task['status']),
                                  ),
                                ),
                                child: Text(
                                  capitalizeFirst(task['status']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: getStatusColor(task['status']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}