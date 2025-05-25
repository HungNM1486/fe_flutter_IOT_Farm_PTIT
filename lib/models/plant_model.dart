class PlantModel {
  String? id;
  String? name;
  String? image;
  String? sysImg;
  String? note;
  String? status;
  String? startDate;
  String? endDate;
  String? address;
  String? unit;
  double? yieldAmount;
  String? rating;
  String? qualityDescription;
  String? locationId;

  PlantModel({
    this.id,
    this.name,
    this.image,
    this.note,
    this.status,
    this.sysImg,
    this.startDate,
    this.endDate,
    this.address,
    this.unit,
    this.yieldAmount,
    this.rating,
    this.qualityDescription,
    this.locationId,
  });

  PlantModel.fromJson(Map<String, dynamic> json) {
    id = json['_id'] ?? "";
    name = json['name'] ?? "";
    image = json['img'] ?? "";
    note = json['note'] ?? "";
    status = json['status'] ?? "";
    sysImg = json['img'] ?? "";
    startDate = json['startdate'] ?? "";
    endDate = json['plantingDate'] ?? "";
    address = json['address'] ?? "";

    // Parse yield object
    if (json['yield'] != null && json['yield'] is Map) {
      Map<String, dynamic> yieldData = json['yield'] as Map<String, dynamic>;
      unit = yieldData['unit'] ?? "";
      yieldAmount = yieldData['amount']?.toDouble() ?? 0.0;
    } else {
      unit = "";
      yieldAmount = 0.0;
    }

    // Parse quality object
    if (json['quality'] != null && json['quality'] is Map) {
      Map<String, dynamic> qualityData =
          json['quality'] as Map<String, dynamic>;
      rating = qualityData['rating'] ?? "";
      qualityDescription = qualityData['description'] ?? "";
    } else {
      rating = "";
      qualityDescription = "";
    }

    // Parse locationId
    if (json['locationId'] != null && json['locationId'] is Map) {
      Map<String, dynamic> locationData =
          json['locationId'] as Map<String, dynamic>;
      locationId = locationData['_id'] ?? "";
    } else {
      locationId = json['locationId'] ?? "";
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['note'] = note;
    data['locationId'] = locationId;
    return data;
  }

  @override
  String toString() {
    return 'PlantModel{id: $id, name: $name, image: $image, note: $note, status: $status, startDate: $startDate, endDate: $endDate, address: $address, yieldAmount: $yieldAmount, unit: $unit, rating: $rating, qualityDescription: $qualityDescription}';
  }
}
