class CareTaskModel {
  final String id;
  final String plantId;
  final String name;
  final String type;
  final DateTime scheduledDate;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareTaskModel({
    required this.id,
    required this.plantId,
    required this.name,
    required this.type,
    required this.scheduledDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CareTaskModel.fromJson(Map<String, dynamic> json) {
    return CareTaskModel(
      id: json['_id'] ?? '',
      plantId: json['plantId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      scheduledDate: DateTime.parse(json['scheduled_date']),
      note: json['note'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'plantId': plantId,
      'name': name,
      'type': type,
      'scheduled_date': scheduledDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
