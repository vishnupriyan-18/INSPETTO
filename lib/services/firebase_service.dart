import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/visit_model.dart';
import '../models/activity_log_model.dart';
import '../models/notification_model.dart';
import 'cloudinary_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── MASTER DATA ────────────────────────────────────────────
  Future<List<String>> getDepartments() async {
    final doc = await _db.collection('masterData').doc('departments').get();
    if (doc.exists) {
      return List<String>.from(doc.data()?['list'] ?? []);
    }
    return ['TNRD', 'TWAD', 'Highways', 'Municipality', 'Corporation'];
  }

  Future<List<String>> getDistricts() async {
    final doc = await _db.collection('masterData').doc('districts').get();
    if (doc.exists) {
      return List<String>.from(doc.data()?['list'] ?? []);
    }
    return ['Coimbatore', 'Chennai', 'Erode', 'Salem'];
  }

  // ─── EMPLOYEES ──────────────────────────────────────────────
  Future<UserModel?> getEmployeeById(String employeeId) async {
    final upper = employeeId.toUpperCase();
    QuerySnapshot q = await _db
        .collection('employees')
        .where('employeeId', isEqualTo: upper)
        .limit(1)
        .get();
    if (q.docs.isEmpty) {
      q = await _db
          .collection('employees')
          .where('employeeId', isEqualTo: employeeId)
          .limit(1)
          .get();
    }
    if (q.docs.isNotEmpty) {
      final data = q.docs.first.data() as Map<String, dynamic>;
      return UserModel.fromMap(data, docId: q.docs.first.id);
    }
    return null;
  }

  Stream<List<UserModel>> getEmployeesStream({String? role, String? hodId}) {
    Query query = _db.collection('employees');
    if (role != null) query = query.where('role', isEqualTo: role);
    if (hodId != null) query = query.where('hodId', isEqualTo: hodId);
    return query.snapshots().map((snap) => snap.docs
        .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, docId: d.id))
        .toList());
  }

  Future<void> createEmployee(UserModel user) async {
    await _db.collection('employees').doc(user.employeeId).set(user.toMap());
  }

  Future<void> updateEmployeeStatus(String employeeId, bool isActive) async {
    await _db.collection('employees').doc(employeeId).update({'isActive': isActive});
  }

  Future<void> updateFcmToken(String employeeId, String token) async {
    await _db.collection('employees').doc(employeeId).update({'fcmToken': token});
  }

  // ─── TASKS ──────────────────────────────────────────────────
  Future<String> createTask(TaskModel task) async {
    final ref = _db.collection('tasks').doc();
    final t = TaskModel(
      id: ref.id,
      title: task.title,
      location: task.location,
      purpose: task.purpose,
      priority: task.priority,
      deadline: task.deadline,
      assignedTo: task.assignedTo,
      createdBy: task.createdBy,
      status: task.status,
      department: task.department,
      district: task.district,
    );
    await ref.set(t.toMap());
    return ref.id;
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    final doc = await _db.collection('tasks').doc(taskId).get();
    if (doc.exists && doc.data() != null) {
      return TaskModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<List<TaskModel>> getTasksForOfficer(String officerId) {
    return _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: officerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<TaskModel>> getTasksForHod(String hodId) {
    return _db
        .collection('tasks')
        .where('createdBy', isEqualTo: hodId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<TaskModel>> getTasksByDistrict(String district) {
    return _db
        .collection('tasks')
        .where('district', isEqualTo: district)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _db.collection('tasks').doc(taskId).update({'status': status});
  }

  Future<void> incrementTaskVisits(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'totalVisits': FieldValue.increment(1),
      'lastVisitAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String taskId) async {
    try {
      // 1. Fetch associated visits
      final visitSnap = await _db.collection('visits').where('taskId', isEqualTo: taskId).get();
      
      for (var doc in visitSnap.docs) {
        final visit = VisitModel.fromMap(doc.data(), doc.id);
        
        // 2. Delete assets from Cloudinary
        await CloudinaryService().deleteImage(visit.photoUrl);
        await CloudinaryService().deleteImage(visit.signatureUrl);
        await CloudinaryService().deleteMultipleImages(visit.additionalPhotos);
        
        // 3. Delete visit doc
        await doc.reference.delete();
      }

      // 4. Delete task doc
      await _db.collection('tasks').doc(taskId).delete();
    } catch (e) {
      throw 'Error deleting task: $e';
    }
  }

  // ─── VISITS ─────────────────────────────────────────────────
  Future<String> submitVisit(VisitModel visit) async {
    final ref = _db.collection('visits').doc();
    final v = VisitModel(
      id: ref.id,
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
      status: 'pending',
      isSuspicious: visit.isSuspicious,
      department: visit.department,
      district: visit.district,
    );
    await ref.set(v.toMap());
    return ref.id;
  }

  Future<void> submitVisitBatch({
    required VisitModel visit,
    required String hodId,
  }) async {
    final batch = _db.batch();

    // 1. Visit Doc
    final visitRef = _db.collection('visits').doc();
    final v = visit.copyWith(id: visitRef.id, status: 'pending');
    batch.set(visitRef, v.toMap());

    // 2. Update Task
    final taskRef = _db.collection('tasks').doc(visit.taskId);
    batch.update(taskRef, {
      'totalVisits': FieldValue.increment(1),
      'lastVisitAt': FieldValue.serverTimestamp(),
      'status': 'inprogress',
    });

    // 3. Notification
    final notifRef = _db.collection('notifications').doc();
    final notif = NotificationModel(
      toUserId: hodId,
      taskId: visit.taskId,
      title: 'Visit Report Submitted',
      message: 'Officer ${visit.officerId} submitted a visit report.',
      type: 'report_submitted',
    );
    batch.set(notifRef, notif.toMap());

    // 4. Activity Log
    final logRef = _db.collection('activityLogs').doc();
    final log = ActivityLogModel(
      action: 'visit_submitted',
      userId: visit.officerId,
      taskId: visit.taskId,
      visitId: visitRef.id,
    );
    batch.set(logRef, log.toMap());

    await batch.commit();
  }

  Stream<List<VisitModel>> getVisitsForTask(String taskId) {
    return _db
        .collection('visits')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => VisitModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<VisitModel>> getVisitsByDistrict(String district) {
    return _db
        .collection('visits')
        .where('district', isEqualTo: district)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => VisitModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> approveVisit(String visitId, String taskId) async {
    final batch = _db.batch();
    batch.update(_db.collection('visits').doc(visitId), {'status': 'approved'});
    batch.update(_db.collection('tasks').doc(taskId), {'status': 'approved'});
    await batch.commit();
  }

  Future<void> rejectVisit(
      String visitId, String taskId, String reason) async {
    // 1. Fetch visit to get image URLs
    final visitDoc = await _db.collection('visits').doc(visitId).get();
    if (visitDoc.exists) {
      final visit = VisitModel.fromMap(visitDoc.data()!, visitDoc.id);
      
      // 2. Delete assets from Cloudinary
      await CloudinaryService().deleteImage(visit.photoUrl);
      await CloudinaryService().deleteImage(visit.signatureUrl);
      await CloudinaryService().deleteMultipleImages(visit.additionalPhotos);
    }

    final batch = _db.batch();
    batch.update(_db.collection('visits').doc(visitId), {
      'status': 'rejected',
      'rejectionReason': reason,
      // Clear URLs since files are deleted
      'photoUrl': '',
      'signatureUrl': '',
      'additionalPhotos': [],
    });
    batch.update(_db.collection('tasks').doc(taskId), {'status': 'rejected'});
    await batch.commit();
  }

  // ─── ACTIVITY LOGS ──────────────────────────────────────────
  Future<void> addActivityLog(ActivityLogModel log) async {
    await _db.collection('activityLogs').add(log.toMap());
  }

  // ─── NOTIFICATIONS ──────────────────────────────────────────
  Future<void> sendNotification(NotificationModel notification) async {
    await _db.collection('notifications').add(notification.toMap());
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'isRead': true});
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
