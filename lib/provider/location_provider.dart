import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/models/location_model.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationProvider with ChangeNotifier {
  String baseUrl = BaseUrl.baseUrl;
  bool _loading = false;
  bool get loading => _loading;
  List<LocationModel> _locations = [];
  List<LocationModel> get locations => _locations;
  void reset() {
    _locations = [];
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchLocations(
      {int page = 1, int limit = 10, String? search}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot fetch locations');
      return;
    }
    _loading = true;
    notifyListeners();
    print('Fetching locations...');
    _locations = [];
    try {
      var url = '$baseUrl/api/locations?page=$page&limit=$limit';
      print("lấy locations");
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final dynamic dataField = body['data'];
        List<dynamic> dataList = [];
        if (dataField is List) {
          dataList = dataField;
        } else if (dataField is Map && dataField['locations'] is List) {
          dataList = dataField['locations'];
        } else if (dataField is Map && dataField['data'] is List) {
          dataList = dataField['data'];
        } else {
          dataList = [];
        }
        _locations = dataList
            .map((location) => LocationModel.fromJson(location))
            .toList();
        print('Parsed locations: $_locations');
        print('Response body: ${response.body}');
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      print(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<LocationModel?> fetchLocationDetail(String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot fetch location detail');
      return null;
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/locations/$locationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return LocationModel.fromJson(body['data']);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<bool> addLocation(
      String name, String description, String area, String locationCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot add location');
      return false;
    }
    _loading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/locations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'area': area,
          'location_code': locationCode,
        }),
      );
      print('Response status: [38;5;2m${response.statusCode}[0m');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchLocations();
        return true;
      } else {
        throw Exception('Failed to add location');
      }
    } catch (e) {
      print(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateLocation(String id, String name, String description,
      String area, String locationCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot update location');
      return false;
    }
    _loading = true;
    notifyListeners();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/locations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'area': area,
          'location_code': locationCode,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchLocations();
        return true;
      } else {
        throw Exception('Failed to update location');
      }
    } catch (e) {
      print(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLocation(String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot delete location');
      return false;
    }
    _loading = true;
    notifyListeners();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/locations/$locationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchLocations();
        return true;
      } else {
        throw Exception('Failed to delete location');
      }
    } catch (e) {
      print(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
