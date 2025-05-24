import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/models/care_task_model.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:http/http.dart' as http;

class CareTaskProvider with ChangeNotifier {
  String baseUrl = BaseUrl.baseUrl;
  bool _loading = false;
  bool get loading => _loading;
  List<CareTaskModel> _tasks = [];
  List<CareTaskModel> get tasks => _tasks;
  CareTaskModel? _task;
  CareTaskModel? get task => _task;

  Future<void> fetchCareTasks(String plantId,
      {String? status, bool? upcoming, int? days}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot fetch caretasks');
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      // SỬA ĐOẠN NÀY: truyền plantId qua query, không phải path
      String url = '$baseUrl/api/caretask?plantId=$plantId';
      List<String> params = [];
      if (status != null) params.add('status=$status');
      if (upcoming != null)
        params.add('upcoming=${upcoming ? 'true' : 'false'}');
      if (days != null) params.add('days=$days');
      if (params.isNotEmpty) url += '&' + params.join('&');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('[fetchCareTasks] url: $url');
      print('[fetchCareTasks] response: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'] is List
            ? body['data']
            : (body['data']['tasks'] ?? body['data']);
        _tasks = data.map((task) => CareTaskModel.fromJson(task)).toList();
      } else {
        throw Exception('Failed to load caretasks');
      }
    } catch (e) {
      print(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addCareTask(String plantId, String name, String type,
      DateTime scheduledDate, String note) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot add caretask');
      return false;
    }
    _loading = true;
    notifyListeners();
    try {
      final bodyData = {
        'plantId': plantId, // Đưa plantId vào body
        'name': name,
        'type': type,
        'scheduled_date': scheduledDate.toIso8601String(),
        'note': note,
      };
      print('[addCareTask] plantId: $plantId');
      print('[addCareTask] body: ' + json.encode(bodyData));
      print('[addCareTask] url: ' + '$baseUrl/api/caretask');
      final response = await http.post(
        Uri.parse('$baseUrl/api/caretask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bodyData),
      );
      print('[addCareTask] response.statusCode: ' +
          response.statusCode.toString());
      print('[addCareTask] response.body: ' + response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCareTasks(plantId);
        return true;
      } else {
        throw Exception('Failed to add caretask');
      }
    } catch (e) {
      print('[addCareTask] error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCareTask(String plantId, String taskId,
      {String? name,
      String? type,
      DateTime? scheduledDate,
      String? note}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot update caretask');
      return false;
    }
    _loading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> bodyData = {};
      if (name != null) bodyData['name'] = name;
      if (type != null) bodyData['type'] = type;
      if (scheduledDate != null)
        bodyData['scheduled_date'] = scheduledDate.toIso8601String();
      if (note != null) bodyData['note'] = note;
      final response = await http.put(
        Uri.parse('$baseUrl/api/caretask/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bodyData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCareTasks(plantId);
        return true;
      } else {
        throw Exception('Failed to update caretask');
      }
    } catch (e) {
      print(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCareTask(String plantId, String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot delete caretask');
      return false;
    }
    _loading = true;
    notifyListeners();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/caretask/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCareTasks(plantId);
        return true;
      } else {
        throw Exception('Failed to delete caretask');
      }
    } catch (e) {
      print(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<CareTaskModel?> getCareTask(String plantId, String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot get caretask');
      return null;
    }
    _loading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/caretask/$plantId/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        _task = CareTaskModel.fromJson(body['data']);
        return _task;
      } else {
        throw Exception('Failed to get caretask');
      }
    } catch (e) {
      print(e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
