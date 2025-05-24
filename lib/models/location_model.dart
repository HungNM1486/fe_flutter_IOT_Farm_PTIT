class LocationModel {
  final String id;
  final String name;
  final String description;
  final String area;
  final String userId;
  final String locationCode;
  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.area,
    required this.userId,
    required this.locationCode,
  });
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['_id'] ?? "",
      name: json['name'] ?? "",
      description: json['description'] ?? "",
      area: json['area'] ?? "",
      userId: json['userId'] ?? "",
      locationCode: json['location_code'] ?? "",
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'area': area,
      'userId': userId,
      'location_code': locationCode,
    };
  }
}
