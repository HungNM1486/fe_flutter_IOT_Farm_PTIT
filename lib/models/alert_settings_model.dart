class AlertSettingsModel {
  final String? id;
  final String locationId;
  final double temperatureMin;
  final double temperatureMax;
  final double soilMoistureMin;
  final double soilMoistureMax;
  final double lightIntensityMin;
  final double lightIntensityMax;
  final double gasMin;
  final double gasMax;

  AlertSettingsModel({
    this.id,
    required this.locationId,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.soilMoistureMin,
    required this.soilMoistureMax,
    required this.lightIntensityMin,
    required this.lightIntensityMax,
    required this.gasMin,
    required this.gasMax,
  });

  factory AlertSettingsModel.fromJson(Map<String, dynamic> json) {
    return AlertSettingsModel(
      id: json['_id'],
      locationId: json['locationId'] ?? '',
      temperatureMin: (json['temperature_min'] ?? 15).toDouble(),
      temperatureMax: (json['temperature_max'] ?? 35).toDouble(),
      soilMoistureMin: (json['soil_moisture_min'] ?? 30).toDouble(),
      soilMoistureMax: (json['soil_moisture_max'] ?? 80).toDouble(),
      lightIntensityMin: (json['light_intensity_min'] ?? 300).toDouble(),
      lightIntensityMax: (json['light_intensity_max'] ?? 800).toDouble(),
      gasMin: (json['gas_min'] ?? 0).toDouble(),
      gasMax: (json['gas_max'] ?? 1000).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'temperature_min': temperatureMin,
      'temperature_max': temperatureMax,
      'soil_moisture_min': soilMoistureMin,
      'soil_moisture_max': soilMoistureMax,
      'light_intensity_min': lightIntensityMin,
      'light_intensity_max': lightIntensityMax,
      'gas_min': gasMin,
      'gas_max': gasMax,
    };
  }

  factory AlertSettingsModel.defaultSettings(String locationId) {
    return AlertSettingsModel(
      locationId: locationId,
      temperatureMin: 15,
      temperatureMax: 35,
      soilMoistureMin: 30,
      soilMoistureMax: 80,
      lightIntensityMin: 300,
      lightIntensityMax: 800,
      gasMin: 0,
      gasMax: 1000,
    );
  }

  AlertSettingsModel copyWith({
    String? id,
    String? locationId,
    double? temperatureMin,
    double? temperatureMax,
    double? soilMoistureMin,
    double? soilMoistureMax,
    double? lightIntensityMin,
    double? lightIntensityMax,
    double? gasMin,
    double? gasMax,
  }) {
    return AlertSettingsModel(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      temperatureMin: temperatureMin ?? this.temperatureMin,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      soilMoistureMin: soilMoistureMin ?? this.soilMoistureMin,
      soilMoistureMax: soilMoistureMax ?? this.soilMoistureMax,
      lightIntensityMin: lightIntensityMin ?? this.lightIntensityMin,
      lightIntensityMax: lightIntensityMax ?? this.lightIntensityMax,
      gasMin: gasMin ?? this.gasMin,
      gasMax: gasMax ?? this.gasMax,
    );
  }
}