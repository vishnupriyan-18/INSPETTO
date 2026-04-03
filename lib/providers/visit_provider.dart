import 'package:flutter/material.dart';
import '../models/visit_model.dart';
import '../models/activity_log_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';

class VisitProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  // Submit visit with suspicious detection
  Future<void> submitVisit({
    required VisitModel visit,
    required String hodId,
    required DateTime? lastVisitTime,
  }) async {
    // Suspicious detection: GPS accuracy > 50m OR submitted within 2 min of last visit
    bool isSusp = visit.gpsAccuracy > 50;
    if (lastVisitTime != null) {
      final diff = DateTime.now().difference(lastVisitTime).inMinutes;
      if (diff < 2) isSusp = true;
    }

    final v = visit.copyWith(isSuspicious: isSusp);

    // Optimized batch operation replaces multiple individual calls
    await _fs.submitVisitBatch(
      visit: v,
      hodId: hodId,
    );
  }

  Stream<List<VisitModel>> visitsForTask(String taskId) =>
      _fs.getVisitsForTask(taskId);

  Stream<List<VisitModel>> districtVisits(String district) =>
      _fs.getVisitsByDistrict(district);

  Future<void> approveVisit({
    required String visitId,
    required String taskId,
    required String officerId,
    required String hodId,
    required String remarks,
  }) async {
    await _fs.approveVisit(visitId, taskId);
    await _fs.sendNotification(NotificationModel(
      toUserId: officerId,
      taskId: taskId,
      title: 'Visit Approved',
      message: 'Your visit report has been approved.',
      type: 'approved',
    ));
    await _fs.addActivityLog(ActivityLogModel(
      action: 'visit_approved',
      userId: hodId,
      taskId: taskId,
      visitId: visitId,
      remarks: remarks,
    ));
  }

  Future<void> rejectVisit({
    required String visitId,
    required String taskId,
    required String officerId,
    required String hodId,
    required String reason,
  }) async {
    await _fs.rejectVisit(visitId, taskId, reason);
    await _fs.sendNotification(NotificationModel(
      toUserId: officerId,
      taskId: taskId,
      title: 'Visit Rejected',
      message: 'Your visit report was rejected: $reason',
      type: 'rejected',
    ));
    await _fs.addActivityLog(ActivityLogModel(
      action: 'visit_rejected',
      userId: hodId,
      taskId: taskId,
      visitId: visitId,
      remarks: reason,
    ));
  }
}
