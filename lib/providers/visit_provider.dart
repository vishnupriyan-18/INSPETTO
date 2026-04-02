import 'package:flutter/material.dart';
import '../models/visit_model.dart';
import '../models/activity_log_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';

class VisitProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  // Submit visit with suspicious detection
  Future<String> submitVisit({
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

    final v = VisitModel(
      id: '',
      taskId: visit.taskId,
      officerId: visit.officerId,
      photoUrl: visit.photoUrl,
      additionalPhotos: visit.additionalPhotos,
      latitude: visit.latitude,
      longitude: visit.longitude,
      address: visit.address,
      gpsAccuracy: visit.gpsAccuracy,
      photoDateTime: visit.photoDateTime,
      progress: visit.progress,
      remarks: visit.remarks,
      signatureUrl: visit.signatureUrl,
      isFinalVisit: visit.isFinalVisit,
      isSuspicious: isSusp,
      department: visit.department,
      district: visit.district,
    );

    final visitId = await _fs.submitVisit(v);
    await _fs.incrementTaskVisits(visit.taskId);

    // Status → inprogress after first visit
    await _fs.updateTaskStatus(visit.taskId, 'inprogress');

    // Notify HOD
    await _fs.sendNotification(NotificationModel(
      toUserId: hodId,
      taskId: visit.taskId,
      title: 'Visit Report Submitted',
      message: 'Officer ${visit.officerId} submitted a visit report.',
      type: 'report_submitted',
    ));

    await _fs.addActivityLog(ActivityLogModel(
      action: 'visit_submitted',
      userId: visit.officerId,
      taskId: visit.taskId,
      visitId: visitId,
    ));

    return visitId;
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
