class EmergencyCallModel {
  final String id;
  final String vetId;
  final String callerName;
  final String callerPhone;
  final String? petDescription;
  final String status;
  final DateTime createdAt;

  const EmergencyCallModel({
    required this.id,
    required this.vetId,
    required this.callerName,
    required this.callerPhone,
    this.petDescription,
    required this.status,
    required this.createdAt,
  });

  factory EmergencyCallModel.fromJson(Map<String, dynamic> json) {
    return EmergencyCallModel(
      id: json['id'] as String,
      vetId: json['vetId'] as String,
      callerName: json['callerName'] as String,
      callerPhone: json['callerPhone'] as String,
      petDescription: json['petDescription'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
