import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/models/plant_model.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class PlantProvider with ChangeNotifier {
  String baseUrl = BaseUrl.baseUrl;
  bool _loading = false;
  bool get loading => _loading;
  List<PlantModel> _plants = [];
  PlantModel? _plant;
  List<PlantModel> get plants => _plants;
  PlantModel? get plant => _plant;

  Future<bool> deletePlant(String plantId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot delete plant');
      return false;
    }
    _loading = true;
    notifyListeners();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/plants/$plantId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        // Xóa khỏi danh sách local
        _plants.removeWhere((plant) => plant.id == plantId);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to delete plant: ${response.statusCode}');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchPlantsByLocation(String locationId,
      {int page = 1,
      int limit = 10,
      String? status,
      String? search,
      bool harvested = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot fetch plants');
      return false;
    }
    _loading = true;
    notifyListeners();
    print('Fetching plants...');
    _plants = [];

    try {
      String url;
      if (harvested) {
        url =
            '$baseUrl/api/plants/$locationId/harvested?page=$page&limit=$limit';
      } else {
        url = '$baseUrl/api/plants/$locationId/plants?page=$page&limit=$limit';
      }

      if (status != null && status.isNotEmpty) url += '&status=$status';
      if (search != null && search.isNotEmpty) url += '&search=$search';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data']['plants'] ?? body['data'];
        _plants = data.map((plant) => PlantModel.fromJson(plant)).toList();
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to load plants: ${response.statusCode}');
        print('Response body: ${response.body}');
        _loading = false;
        notifyListeners();
        throw Exception('Failed to load plants');
      }
    } catch (e) {
      print(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> fetchPlantById(String plantId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot fetch plant');
      return false;
    }
    _loading = true;
    notifyListeners();
    print('Fetching plant...');
    _plant = null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/plants/$plantId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final Map<String, dynamic> data = body['data'];
        _plant = PlantModel.fromJson(data);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to load plant: ${response.statusCode}');
        print('Response body: ${response.body}');
        _loading = false;
        notifyListeners();
        throw Exception('Failed to load plant');
      }
    } catch (e) {
      _loading = false;
      notifyListeners();
      print(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> createPlant({
    required String locationId,
    required String name,
    File? image,
    String? status,
    String? note,
    String? startdate,
    String? plantingDate,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot create plant');
      return false;
    }
    _loading = true;
    notifyListeners();
    print('Creating plant...');
    final dio = Dio();
    final formData = FormData();
    formData.fields.add(MapEntry('name', name));
    if (status != null) formData.fields.add(MapEntry('status', status));
    if (note != null) formData.fields.add(MapEntry('note', note));
    if (startdate != null)
      formData.fields.add(MapEntry('startdate', startdate));
    if (plantingDate != null)
      formData.fields.add(MapEntry('plantingDate', plantingDate));
    if (address != null) formData.fields.add(MapEntry('address', address));
    if (image != null) {
      final filename = image.path.split('/').last;
      if (!await image.exists()) {
        print('File không tồn tại: ${image.path}');
        _loading = false;
        notifyListeners();
        return false;
      }
      if (!_isImageFile(image.path)) {
        print('File không phải là ảnh hợp lệ: ${image.path}');
        _loading = false;
        notifyListeners();
        return false;
      }
      final mimeType = _getMimeTypeFromExtension(image.path);
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            image.path,
            filename: filename,
            contentType: mimeType,
          ),
        ),
      );
    }
    final uri = Uri.parse('$baseUrl/api/plants/$locationId');
    try {
      final response = await dio.post(
        uri.toString(),
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPlantsByLocation(locationId);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to create plant: ${response.statusCode}');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Hàm để lấy MIME type từ file extension
  MediaType _getMimeTypeFromExtension(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.webp':
        return MediaType('image', 'webp');
      case '.bmp':
        return MediaType('image', 'bmp');
      default:
        return MediaType('image', 'jpeg'); // Mặc định là jpeg
    }
  }

  // Hàm để kiểm tra nếu file là ảnh hợp lệ
  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
        .contains(extension);
  }

  Future<bool> updatePlant({
    required String plantId,
    String? name,
    File? image,
    String? status,
    String? note,
    String? plantingDate,
    String? address,
    String? yieldAmount,
    String? yieldUnit,
    String? qualityRating,
    String? qualityDescription,
    bool? removeImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot update plant');
      return false;
    }
    if (plantId.isEmpty) {
      print('Plant ID is null or empty, cannot update plant');
      return false;
    }
    _loading = true;
    notifyListeners();
    print('Updating plant...');

    final dio = Dio();
    final formData = FormData();

    if (name != null) formData.fields.add(MapEntry('name', name));
    if (status != null) formData.fields.add(MapEntry('status', status));
    if (note != null) formData.fields.add(MapEntry('note', note));
    if (plantingDate != null)
      formData.fields.add(MapEntry('plantingDate', plantingDate));
    if (address != null) formData.fields.add(MapEntry('address', address));
    if (removeImage == true)
      formData.fields.add(MapEntry('removeImage', 'true'));

    // Harvest fields
    if (yieldAmount != null)
      formData.fields.add(MapEntry('yield[amount]', yieldAmount));
    if (yieldUnit != null)
      formData.fields.add(MapEntry('yield[unit]', yieldUnit));
    if (qualityRating != null)
      formData.fields.add(MapEntry('quality[rating]', qualityRating));
    if (qualityDescription != null)
      formData.fields.add(MapEntry('quality[description]', qualityDescription));

    if (image != null) {
      final filename = image.path.split('/').last;
      if (!await image.exists()) {
        print('File không tồn tại: ${image.path}');
        _loading = false;
        notifyListeners();
        return false;
      }
      if (!_isImageFile(image.path)) {
        print('File không phải là ảnh hợp lệ: ${image.path}');
        _loading = false;
        notifyListeners();
        return false;
      }
      final mimeType = _getMimeTypeFromExtension(image.path);
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            image.path,
            filename: filename,
            contentType: mimeType,
          ),
        ),
      );
    }

    final uri = Uri.parse('$baseUrl/api/plants/$plantId');
    try {
      final response = await dio.put(
        uri.toString(),
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPlantById(plantId);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to update plant: ${response.statusCode}');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error during plant update: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Lấy danh sách cây theo user (chỉ non-harvested)
  Future<bool> fetchPlantsByUser({bool harvested = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot fetch plants by user');
      return false;
    }
    _loading = true;
    notifyListeners();
    print('Fetching plants by user (harvested: $harvested)...');
    _plants = [];

    try {
      final endpoint = harvested ? '/api/plants/harvested' : '/api/plants/all';
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data']['plants'] ?? body['data'];
        _plants = data.map((plant) => PlantModel.fromJson(plant)).toList();
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to load plants by user: ${response.statusCode}');
        print('Response body: ${response.body}');
        _loading = false;
        notifyListeners();
        throw Exception('Failed to load plants by user');
      }
    } catch (e) {
      print(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
    return false;
  }
}
