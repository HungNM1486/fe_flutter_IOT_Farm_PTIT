import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String type;
  final String message;
  final String locationId;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.locationId,
    required this.read,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      locationId: json['locationId'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? message,
    String? locationId,
    bool? read,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      locationId: locationId ?? this.locationId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  String getTypeDisplayName() {
    switch (type) {
      case 'temperature_alert':
        return 'Cảnh báo nhiệt độ';
      case 'soil_moisture_alert':
        return 'Cảnh báo độ ẩm';
      case 'light_intensity_alert':
        return 'Cảnh báo ánh sáng';
      case 'gas_alert':
        return 'Cảnh báo khí gas';
      default:
        return 'Thông báo';
    }
  }

  IconData getTypeIcon() {
    switch (type) {
      case 'temperature_alert':
        return Icons.thermostat;
      case 'soil_moisture_alert':
        return Icons.water_drop;
      case 'light_intensity_alert':
        return Icons.wb_sunny;
      case 'gas_alert':
        return Icons.air;
      default:
        return Icons.notifications;
    }
  }

  Color getTypeColor() {
    switch (type) {
      case 'temperature_alert':
        return Colors.red;
      case 'soil_moisture_alert':
        return Colors.blue;
      case 'light_intensity_alert':
        return Colors.orange;
      case 'gas_alert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}