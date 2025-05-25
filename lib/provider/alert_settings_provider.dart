import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/models/alert_settings_model.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:http/http.dart' as http;

class AlertSettingsProvider with ChangeNotifier {
  String baseUrl = BaseUrl.baseUrl;
  bool _loading = false;
  bool get loading => _loading;
  AlertSettingsModel? _alertSettings;
  AlertSettingsModel? get alertSettings => _alertSettings;

  Future<bool> getAlertSettings(String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot get alert settings');
      return false;
    }
    
    _loading = true;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sensors/alert-settings/$locationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        _alertSettings = AlertSettingsModel.fromJson(body['data']);
        _loading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 404) {
        // Nếu chưa có settings, tạo default
        _alertSettings = AlertSettingsModel.defaultSettings(locationId);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to get alert settings: ${response.statusCode}');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error getting alert settings: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAlertSettings(String locationId, AlertSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot update alert settings');
      return false;
    }
    
    _loading = true;
    notifyListeners();
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/sensors/alert-settings/$locationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(settings.toJson()),
      );
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        _alertSettings = AlertSettingsModel.fromJson(body['data']);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to update alert settings: ${response.statusCode}');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error updating alert settings: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _alertSettings = null;
    _loading = false;
    notifyListeners();
  }
}