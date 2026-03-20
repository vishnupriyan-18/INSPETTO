import 'package:flutter/material.dart';
import 'package:inspetto/themes/app_colors.dart';

class OfficerHistoryScreen extends StatefulWidget {
  final String officerId;
  const OfficerHistoryScreen({super.key, required this.officerId});

  @override
  State<OfficerHistoryScreen> createState() => _OfficerHistoryScreenState();
}

class _OfficerHistoryScreenState extends State<OfficerHistoryScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Approved', 'Rejected', 'Pending'];

  // Dummy history data
  final List<Map<String, dynamic>> _history = [
    {
      'taskId': 'TASK001',
      'title': 'Road Repair Inspection',
      'location': 'Anna Nagar, Chennai',
      'date': '15 Mar 2025',
      'progress': 100,
      'status': 'approved',
      'remarks': 'Road repair completed successfully',
    },
    {
      'taskId': 'TASK002',
      'title': 'Street Light Check',
      'location': 'T Nagar, Chennai',
      'date': '12 Mar 2025',
      'progress': 60,
      'status': 'rejected',
      'remarks': 'Incomplete work found at site',
    },
    {
      'taskId': 'TASK003',
      'title': 'Drainage Inspection',
      'location': 'Velachery, Chennai',
      'date': '10 Mar 2025',
      'progress': 80,
      'status': 'pending',
      'remarks': 'Work in progress',
    },
    {
      'taskId': 'TASK004',
      'title': 'Park Renovation Check',
      'location': 'Adyar, Chennai',
      'date': '08 Mar 2025',
      'progress': 100,
      'status': 'approved',
      'remarks': 'Park renovation completed',
    },
  ];

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == 0) return _history;
    final filter = _filters[_selectedFilter].toLowerCase();
    return _history
        .where((h) => h['status'].toString().toLowerCase() == filter)
        .toList();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return AppColors.approved;
      case 'rejected': return AppColors.rejected;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'pending': return Icons.hourglass_bottom;
      default: return Icons.info;
    }
  }

  String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _filters.length,
                (index) => GestureDetector(
                  onTap: () => setState(() => _selectedFilter = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedFilter == index
                          ? Colors.black
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedFilter == index
                            ? Colors.black
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: _selectedFilter == index
                            ? Colors.white
                            : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // History list
        Expanded(
          child: _filteredHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No visits found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredHistory.length,
                  itemBuilder: (context, index) {
                    final visit = _filteredHistory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and status
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  visit['title'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                getStatusIcon(visit['status']),
                                color: getStatusColor(visit['status']),
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Location
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                visit['location'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Date
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                visit['date'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Progress bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: visit['progress'] / 100,
                                    backgroundColor: AppColors.border,
                                    color: getStatusColor(visit['status']),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${visit['progress']}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(visit['status'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: getStatusColor(visit['status'])),
                            ),
                            child: Text(
                              capitalizeFirst(visit['status']),
                              style: TextStyle(
                                fontSize: 11,
                                color: getStatusColor(visit['status']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}