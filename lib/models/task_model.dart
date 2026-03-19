// Task model - created by HOD, assigned to Field Officer
class TaskModel {
  final String id;
  final String title;
  final String location;
  final String purpose;
  final String priority; // 'high' | 'medium' | 'low'
  final String deadline; // date only, no time
  final String assignedTo; // field officer id
  final String createdBy; // hod id
  final String status; // assigned|accepted|inprogress|completed|approved|rejected|missed
  final String department;

  TaskModel({
    required this.id,
    required this.title,
    required this.location,
    required this.purpose,
    required this.priority,
    required this.deadline,
    required this.assignedTo,
    required this.createdBy,
    required this.status,
    required this.department,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    // TODO: implement
    throw UnimplementedError();
  }

  Map<String, dynamic> toMap() {
    // TODO: implement
    throw UnimplementedError();
  }
}
