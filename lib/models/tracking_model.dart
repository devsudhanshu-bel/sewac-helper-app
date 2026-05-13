class TrackingModel {
  final int id;
  final String workerId;
  final String slno;
  final String? citizenName;
  final String? phoneNumber;
  final String status;
  final String? remarks;
  final DateTime createdAt;

  TrackingModel({
    required this.id,
    required this.workerId,
    required this.slno,
    this.citizenName,
    this.phoneNumber,
    required this.status,
    this.remarks,
    required this.createdAt,
  });

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    return TrackingModel(
      id: json["id"],
      workerId: json["workerId"] ?? "",
      slno: json["slno"] ?? "",
      citizenName: json["citizenName"],
      phoneNumber: json["phoneNumber"],
      status: json["status"] ?? "",
      remarks: json["remarks"],
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}