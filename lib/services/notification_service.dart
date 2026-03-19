// Push notification handling using Firebase FCM
// Member 5 implements this
class NotificationService {
  // TODO: initialize FCM
  Future<void> initialize() async {}

  // TODO: get FCM token
  Future<String?> getToken() async => null;

  // TODO: send notification to officer when task assigned
  Future<void> notifyOfficer(String officerToken, String taskTitle) async {}
}
