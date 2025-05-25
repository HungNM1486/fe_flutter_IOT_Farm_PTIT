import 'package:flutter/material.dart';
import 'package:smart_farm/theme/app_colors.dart';
import 'package:smart_farm/widget/bottom_bar.dart';
import 'package:smart_farm/widget/top_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/utils/base_url.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  bool _loading = false;

  // Giá trị mặc định
  double temperatureMin = 15;
  double temperatureMax = 35;
  double humidityMin = 30;
  double humidityMax = 80;
  double lightMin = 300;
  double lightMax = 800;
  double gasMin = 0;
  double gasMax = 1000;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${BaseUrl.baseUrl}/api/sensors/alert-settings/global'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          temperatureMin = (data['temperature_min'] ?? 15).toDouble();
          temperatureMax = (data['temperature_max'] ?? 35).toDouble();
          humidityMin = (data['humidity_min'] ?? 30).toDouble();
          humidityMax = (data['humidity_max'] ?? 80).toDouble();
          lightMin = (data['light_intensity_min'] ?? 300).toDouble();
          lightMax = (data['light_intensity_max'] ?? 800).toDouble();
          gasMin = (data['gas_min'] ?? 0).toDouble();
          gasMax = (data['gas_max'] ?? 1000).toDouble();
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${BaseUrl.baseUrl}/api/sensors/alert-settings/global'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'temperature_min': temperatureMin,
          'temperature_max': temperatureMax,
          'humidity_min': humidityMin,
          'humidity_max': humidityMax,
          'light_intensity_min': lightMin,
          'light_intensity_max': lightMax,
          'gas_min': gasMin,
          'gas_max': gasMax,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cài đặt cảnh báo'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu cài đặt thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(title: 'Cài đặt cảnh báo', isBack: true),
          ),
          Positioned(
            top: 70 * pix,
            left: 0,
            right: 0,
            bottom: 70 * pix,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff47BFDF).withOpacity(0.5),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16 * pix),
                      child: Column(
                        children: [
                          _buildSettingsCard(pix),
                          SizedBox(height: 20 * pix),
                          _buildSaveButton(pix),
                        ],
                      ),
                    ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Bottombar(type: 5),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(double pix) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * pix),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * pix),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ngưỡng cảnh báo ESP32',
            style: TextStyle(
              fontSize: 18 * pix,
              fontWeight: FontWeight.bold,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 20 * pix),
          _buildSensorSetting(
            pix,
            'Nhiệt độ (°C)',
            Icons.thermostat,
            Colors.red,
            temperatureMin,
            temperatureMax,
            0,
            50,
            (min, max) => setState(() {
              temperatureMin = min;
              temperatureMax = max;
            }),
          ),
          _buildSensorSetting(
            pix,
            'Độ ẩm (%)',
            Icons.water_drop,
            Colors.blue,
            humidityMin,
            humidityMax,
            0,
            100,
            (min, max) => setState(() {
              humidityMin = min;
              humidityMax = max;
            }),
          ),
          _buildSensorSetting(
            pix,
            'Ánh sáng (lux)',
            Icons.wb_sunny,
            Colors.orange,
            lightMin,
            lightMax,
            0,
            2000,
            (min, max) => setState(() {
              lightMin = min;
              lightMax = max;
            }),
          ),
          _buildSensorSetting(
            pix,
            'Khí gas (ppm)',
            Icons.air,
            Colors.purple,
            gasMin,
            gasMax,
            0,
            2000,
            (min, max) => setState(() {
              gasMin = min;
              gasMax = max;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorSetting(
    double pix,
    String title,
    IconData icon,
    Color color,
    double minValue,
    double maxValue,
    double minLimit,
    double maxLimit,
    Function(double, double) onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 24 * pix),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20 * pix),
              SizedBox(width: 8 * pix),
              Text(title,
                  style: TextStyle(
                      fontSize: 16 * pix, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12 * pix),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Min: ${minValue.toInt()}',
                        style: TextStyle(fontSize: 14 * pix)),
                    Slider(
                      value: minValue,
                      min: minLimit,
                      max: maxLimit,
                      activeColor: color,
                      onChanged: (value) => onChanged(value, maxValue),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Max: ${maxValue.toInt()}',
                        style: TextStyle(fontSize: 14 * pix)),
                    Slider(
                      value: maxValue,
                      min: minLimit,
                      max: maxLimit,
                      activeColor: color,
                      onChanged: (value) => onChanged(minValue, value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(double pix) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: EdgeInsets.symmetric(vertical: 16 * pix),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12 * pix)),
        ),
        child: Text(
          'Lưu cài đặt',
          style: TextStyle(
            fontSize: 16 * pix,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
