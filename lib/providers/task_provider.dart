// Handles all task operations
// Member 3 (HOD screens) uses this
import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  // TODO: HOD creates a task
  Future<void> createTask(TaskModel task) async {}

  // TODO: HOD assigns task to officer
  Future<void> assignTask(String taskId, String officerId) async {}

  // TODO: fetch tasks for field officer
  Future<List<TaskModel>> fetchOfficerTasks(String officerId) async => [];

  // TODO: fetch all tasks for HOD
  Future<List<TaskModel>> fetchAllTasks() async => [];

  // TODO: officer accepts task
  Future<void> acceptTask(String taskId) async {}

  // TODO: HOD approves task
  Future<void> approveTask(String taskId) async {}

  // TODO: HOD rejects task
  Future<void> rejectTask(String taskId, String remarks) async {}

  // TODO: update task status
  Future<void> updateStatus(String taskId, String status) async {}
}
