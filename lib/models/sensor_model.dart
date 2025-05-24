class SensorData {
  final String deviceId;
  final int timestamp;
  final double temperature;
  final double humidity;
  final double gas;
  final double light;
  final double soilMoisture;

  SensorData({
    required this.deviceId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.gas,
    required this.light,
    this.soilMoisture = 0,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json['device_id'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      temperature: (json['temperature'] ?? json['nhietdo'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? json['doam'] ?? 0).toDouble(),
      gas: (json['gas'] ?? 0).toDouble(),
      light: (json['light'] ?? json['anhsang'] ?? 0).toDouble(),
      soilMoisture: (json['soilMoisture'] ?? json['doamdat'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'timestamp': timestamp,
      'temperature': temperature,
      'humidity': humidity,
      'gas': gas,
      'light': light,
      'soilMoisture': soilMoisture,
    };
  }

  // Phương thức dự đoán thời tiết dựa trên dữ liệu cảm biến
  String predictWeather() {
    if (humidity > 80 && light < 100) {
      return "Mưa";
    } else if (light > 600 && temperature > 30 && humidity < 60) {
      return "Nắng";
    } else if (light >= 200 && light <= 600 && humidity >= 60) {
      return "Nhiều mây";
    } else {
      return "Nhiều mây";
    }
  }
}
