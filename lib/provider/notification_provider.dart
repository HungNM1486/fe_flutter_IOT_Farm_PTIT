import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/models/notification_model.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:http/http.dart' as http;

class NotificationProvider with ChangeNotifier {
  String baseUrl = BaseUrl.baseUrl;
  bool _loading = false;
  bool get loading => _loading;
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Future<bool> fetchNotifications({int limit = 50, int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return false;

    _loading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications?limit=$limit&page=$page'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        _notifications = data.map((item) => NotificationModel.fromJson(item)).toList();
        _updateUnreadCount();
        return true;
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> fetchUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        _unreadCount = data.length;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error fetching unread notifications: $e');
    }
    return false;
  }

  Future<bool> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(read: true);
          _updateUnreadCount();
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
    return false;
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.read).length;
  }

  void reset() {
    _notifications = [];
    _unreadCount = 0;
    _loading = false;
    notifyListeners();
  }
}