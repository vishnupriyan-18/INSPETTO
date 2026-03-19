// Visit model - submitted by Field Officer for a task
class VisitModel {
  final String id;
  final String taskId;
  final String officerId;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String remarks;
  final int progress; // 0 to 100
  final String signatureUrl;
  final bool isFinalVisit;

  VisitModel({
    required this.id,
    required this.taskId,
    required this.officerId,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.remarks,
    required this.progress,
    required this.signatureUrl,
    required this.isFinalVisit,
  });

  factory VisitModel.fromMap(Map<String, dynamic> map) {
    // TODO: implement
    throw UnimplementedError();
  }

  Map<String, dynamic> toMap() {
    // TODO: implement
    throw UnimplementedError();
  }
}
