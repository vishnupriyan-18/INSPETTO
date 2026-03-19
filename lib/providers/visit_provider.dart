// Handles all visit/inspection report operations
// Member 2 (Field Officer screens) uses this
import 'package:flutter/material.dart';
import '../models/visit_model.dart';

class VisitProvider extends ChangeNotifier {
  List<VisitModel> _visits = [];
  List<VisitModel> get visits => _visits;

  // TODO: submit new visit report
  Future<void> submitVisit(VisitModel visit) async {}

  // TODO: fetch visits for a task
  Future<List<VisitModel>> fetchVisitsForTask(String taskId) async => [];

  // TODO: fetch all visits by officer
  Future<List<VisitModel>> fetchOfficerVisits(String officerId) async => [];

  // TODO: fetch all visits for collector map
  Future<List<VisitModel>> fetchAllVisits() async => [];
}
