import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/activity_log_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  Stream<List<TaskModel>> foTasksStream(String officerId) =>
      _fs.getTasksForOfficer(officerId);

  Stream<List<TaskModel>> hodTasksStream(String hodId) =>
      _fs.getTasksForHod(hodId);

  Stream<List<TaskModel>> districtTasksStream(String district) =>
      _fs.getTasksByDistrict(district);

  Future<String> createTask(TaskModel task, String hodId) async {
    final taskId = await _fs.createTask(task);
    await _fs.sendNotification(NotificationModel(
      toUserId: task.assignedTo,
      taskId: taskId,
      title: 'New Task Assigned',
      message: '${task.title} has been assigned to you.',
      type: 'task_assigned',
    ));
    await _fs.addActivityLog(ActivityLogModel(
      action: 'task_created',
      userId: hodId,
      taskId: taskId,
      remarks: 'Task "${task.title}" created and assigned to ${task.assignedTo}',
    ));
    return taskId;
  }

  Future<void> acceptTask(String taskId, String officerId) async {
    await _fs.updateTaskStatus(taskId, 'accepted');
    await _fs.addActivityLog(ActivityLogModel(
      action: 'task_accepted',
      userId: officerId,
      taskId: taskId,
    ));
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _fs.updateTaskStatus(taskId, status);
  }
}
