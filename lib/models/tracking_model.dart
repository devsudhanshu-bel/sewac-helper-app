class TrackingModel {
  final int id;
  final String workerId;

  final String wetWasteRfid;
  final String dryWasteRfid;

  final String? citizenName;
  final String? phoneNumber;

  final String status;
  final String? remarks;

  // Not Found fields
  final String? address;
  final String? buildingNo;
  final String? floorNo;
  final String? photoUrl;

  final DateTime createdAt;

  TrackingModel({
    required this.id,
    required this.workerId,

    required this.wetWasteRfid,
    required this.dryWasteRfid,

    this.citizenName,
    this.phoneNumber,

    required this.status,
    this.remarks,

    this.address,
    this.buildingNo,
    this.floorNo,
    this.photoUrl,

    required this.createdAt,
  });

  factory TrackingModel.fromJson(
      Map<String, dynamic> json,
      ) {

    // Safety helper function to clean up stringified nulls or empty values from the DB
    String? cleanString(dynamic val) {
      if (val == null) return null;
      String str = val.toString().trim();
      if (str == "null" || str.isEmpty) return null;
      return str;
    }

    return TrackingModel(
      id: json["id"] ?? 0,

      workerId: json["workerId"] ?? "",

      wetWasteRfid: json["wetSlno"] ?? "",

      dryWasteRfid: json["drySlno"] ?? "",

      citizenName: cleanString(json["citizenName"]),

      phoneNumber: cleanString(json["phoneNumber"]),

      status: json["status"] ?? "",

      remarks: cleanString(json["remarks"]),

      // For Not Found cards cleaned globally
      address: cleanString(json["address"]),

      buildingNo: cleanString(json["buildingNo"]),

      floorNo: cleanString(json["floorNo"]),

      photoUrl: cleanString(json["photoUrl"]),

      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
    );
  }
}