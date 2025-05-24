import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/models/user_model.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class AuthProvider with ChangeNotifier {
  String _baseUrl = BaseUrl.baseUrl;
  bool _loading = false;
  String? _token;
  UserModel? _user;

  bool get loading => _loading;
  String? get token => _token;
  UserModel? get user => _user;

  Future<bool> register(String username, String email, String password) async {
    _loading = true;
    notifyListeners();
    print('Registering user...');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'address': '',
          'phone': '',
        }),
      );
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Response data: $data');
        _token = data['data']['token'];
        _user = UserModel.fromJson(data['data']['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        print('Failed to register user: ${response.body}');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error during registration: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        _user = UserModel.fromJson(data['data']['user']);
        print('User logged in: ${_user.toString()}');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
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

  Future<bool> uploadUser({
    File? avatar,
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      print('Token is null, cannot update profile');
      return false;
    }
    _loading = true;
    notifyListeners();
    print('Upload...');

    try {
      final dio = Dio();

      final formData = FormData();

      if (avatar != null) {
        print('Adding avatar file: ${avatar.path}');
        final filename = avatar.path.split('/').last;

        if (!await avatar.exists()) {
          print('File không tồn tại: ${avatar.path}');
          _loading = false;
          notifyListeners();
          return false;
        }

        // Kiểm tra xem có phải là file ảnh hợp lệ không
        if (!_isImageFile(avatar.path)) {
          print('File không phải là ảnh hợp lệ: ${avatar.path}');
          _loading = false;
          notifyListeners();
          return false;
        }

        // Lấy thông tin về file
        final fileStats = await avatar.stat();
        print('File size: ${fileStats.size} bytes');

        // Tạo mimetype chính xác từ extension file
        final mimeType = _getMimeTypeFromExtension(avatar.path);
        print('MIME Type: ${mimeType.type}/${mimeType.subtype}');

        // Thêm file vào form với tên field là avatar và MIME type chính xác
        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(
              avatar.path,
              filename: filename,
              contentType: mimeType,
            ),
          ),
        );
      }

      // Thêm username nếu có
      if (username != null && username.isNotEmpty) {
        formData.fields.add(MapEntry('username', username));
      }

      // Cấu hình request options với headers đúng
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          // Dio sẽ tự động thêm 'Content-Type': 'multipart/form-data'
        },
        validateStatus: (status) {
          // Cho phép tất cả các status codes để xử lý lỗi ở phía client
          return true;
        },
      );

      final endpoint = '$_baseUrl/auth/profile';

      final response = await dio.put(
        endpoint,
        data: formData,
        options: options,
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final responseData = response.data;

        final dynamic data;
        if (responseData is String) {
          try {
            data = jsonDecode(responseData);
          } catch (e) {
            print('Error parsing response data: $e');
            _loading = false;
            notifyListeners();
            return false;
          }
        } else {
          data = responseData;
        }

        try {
          if (data != null &&
              data['data'] != null &&
              data['data']['user'] != null) {
            _user = UserModel.fromJson(data['data']['user']);
          } else if (data != null && data['user'] != null) {
            _user = UserModel.fromJson(data['user']);
          } else if (data != null && data is Map<String, dynamic>) {
            _user = UserModel.fromJson(data);
          }

          print('User updated: ${_user.toString()}');
          _loading = false;
          notifyListeners();
          return true;
        } catch (e) {
          print('Error updating user from response: $e');
          print('Response format: $data');
          _loading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Error case
        print('Server error: ${response.statusCode}, ${response.data}');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error during user update: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
