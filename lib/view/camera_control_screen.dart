import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/provider/sensor_provider.dart';
import 'package:smart_farm/services/websocket_service.dart';
import 'package:smart_farm/theme/app_colors.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:smart_farm/widget/top_bar.dart';
import 'package:intl/intl.dart';

class CameraControlScreen extends StatefulWidget {
  const CameraControlScreen({super.key});

  @override
  State<CameraControlScreen> createState() => _CameraControlScreenState();
}

class _CameraControlScreenState extends State<CameraControlScreen> {
  final WebSocketService _wsService = WebSocketService();
  List<CameraImage> _recentImages = [];
  int _captureInterval = 60; // seconds
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _wsService.connect();
    _wsService.onPredictionReceived(_onNewImage);
  }

  @override
  void dispose() {
    _wsService.clearCallbacks();
    super.dispose();
  }

  void _onNewImage(PredictionResult result) {
    if (mounted) {
      setState(() {
        _recentImages.insert(
            0,
            CameraImage(
              imageUrl: result.imageUrl,
              timestamp: DateTime.now(),
              disease: result.disease,
              confidence: result.probability,
            ));
        // Giữ tối đa 20 ảnh
        if (_recentImages.length > 20) {
          _recentImages.removeRange(20, _recentImages.length);
        }
      });
    }
  }

  Future<void> _captureNow() async {
    setState(() => _isCapturing = true);

    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    sensorProvider.sendCameraCommand("capture");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi lệnh chụp ảnh'),
        backgroundColor: Colors.green,
      ),
    );

    // Reset sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCapturing = false);
    });
  }

  void _updateInterval() {
    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    sensorProvider.sendCameraCommand("interval:${_captureInterval * 1000}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật chu kỳ chụp: $_captureInterval giây'),
        backgroundColor: Colors.green,
      ),
    );
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
            child: TopBar(title: 'Camera ESP32-CAM', isBack: true),
          ),
          Positioned(
            top: 70 * pix,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16 * pix),
                child: Column(
                  children: [
                    _buildControlPanel(pix),
                    SizedBox(height: 20 * pix),
                    _buildRecentImages(pix),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(double pix) {
    return Container(
      padding: EdgeInsets.all(20 * pix),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * pix),
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
            'Điều khiển Camera',
            style: TextStyle(
              fontSize: 20 * pix,
              fontWeight: FontWeight.bold,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 20 * pix),

          // Capture Now Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCapturing ? null : _captureNow,
              icon: _isCapturing
                  ? SizedBox(
                      width: 20 * pix,
                      height: 20 * pix,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.camera_alt, size: 24 * pix),
              label: Text(
                _isCapturing ? 'Đang chụp...' : 'Chụp ảnh ngay',
                style: TextStyle(
                  fontSize: 16 * pix,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16 * pix),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * pix),
                ),
              ),
            ),
          ),

          SizedBox(height: 24 * pix),

          // Interval Settings
          Text(
            'Chu kỳ chụp tự động',
            style: TextStyle(
              fontSize: 16 * pix,
              fontWeight: FontWeight.w600,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 12 * pix),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Mỗi $_captureInterval giây',
                  style: TextStyle(
                    fontSize: 14 * pix,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                '$_captureInterval s',
                style: TextStyle(
                  fontSize: 16 * pix,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          Slider(
            value: _captureInterval.toDouble(),
            min: 10,
            max: 300,
            divisions: 29,
            activeColor: AppColors.primaryGreen,
            onChanged: (value) {
              setState(() {
                _captureInterval = value.toInt();
              });
            },
            onChangeEnd: (value) {
              _updateInterval();
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10s',
                  style: TextStyle(fontSize: 12 * pix, color: Colors.grey)),
              Text('5 phút',
                  style: TextStyle(fontSize: 12 * pix, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentImages(double pix) {
    return Container(
      padding: EdgeInsets.all(20 * pix),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * pix),
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
          Row(
            children: [
              Icon(Icons.photo_library,
                  color: AppColors.primaryGreen, size: 20 * pix),
              SizedBox(width: 8 * pix),
              Text(
                'Ảnh gần đây',
                style: TextStyle(
                  fontSize: 18 * pix,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
              const Spacer(),
              Text(
                '${_recentImages.length} ảnh',
                style: TextStyle(
                  fontSize: 14 * pix,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * pix),
          if (_recentImages.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.camera_enhance,
                    size: 48 * pix,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8 * pix),
                  Text(
                    'Chưa có ảnh nào',
                    style: TextStyle(
                      fontSize: 14 * pix,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12 * pix,
                mainAxisSpacing: 12 * pix,
                childAspectRatio: 1,
              ),
              itemCount: _recentImages.length,
              itemBuilder: (context, index) {
                final imageData = _recentImages[index];
                return _buildImageCard(pix, imageData);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(double pix, CameraImage imageData) {
    final isHealthy = imageData.disease.toLowerCase().contains('healthy');
    final diseaseColor = isHealthy ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () => _showImageDetail(imageData),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12 * pix),
          border: Border.all(color: diseaseColor.withOpacity(0.5), width: 2),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10 * pix)),
                child: Image.network(
                  BaseUrl.baseUrl + imageData.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, size: 40 * pix),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8 * pix),
              child: Column(
                children: [
                  Text(
                    DateFormat('HH:mm').format(imageData.timestamp),
                    style: TextStyle(
                      fontSize: 11 * pix,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2 * pix),
                  Text(
                    _translateDisease(imageData.disease),
                    style: TextStyle(
                      fontSize: 9 * pix,
                      color: diseaseColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${(imageData.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 9 * pix,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDetail(CameraImage imageData) {
    final isHealthy = imageData.disease.toLowerCase().contains('healthy');
    final diseaseColor = isHealthy ? Colors.green : Colors.red;

    showDialog(
      context: context,
      builder: (context) {
        final pix = MediaQuery.of(context).size.width / 375;
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16 * pix)),
          child: Container(
            padding: EdgeInsets.all(20 * pix),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12 * pix),
                  child: Image.network(
                    BaseUrl.baseUrl + imageData.imageUrl,
                    width: 250 * pix,
                    height: 200 * pix,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 16 * pix),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(imageData.timestamp),
                  style: TextStyle(
                      fontSize: 14 * pix, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12 * pix),

                // Disease info
                Container(
                  padding: EdgeInsets.all(12 * pix),
                  decoration: BoxDecoration(
                    color: diseaseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8 * pix),
                    border: Border.all(color: diseaseColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isHealthy ? Icons.check_circle : Icons.warning,
                            color: diseaseColor,
                            size: 20 * pix,
                          ),
                          SizedBox(width: 8 * pix),
                          Expanded(
                            child: Text(
                              _translateDisease(imageData.disease),
                              style: TextStyle(
                                fontSize: 16 * pix,
                                fontWeight: FontWeight.bold,
                                color: diseaseColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * pix),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Độ chính xác:',
                            style: TextStyle(
                                fontSize: 14 * pix, color: Colors.grey[600]),
                          ),
                          Text(
                            '${(imageData.confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16 * pix,
                              fontWeight: FontWeight.bold,
                              color: diseaseColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16 * pix),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _translateDisease(String disease) {
    final translations = {
      'Pepper_bell_healthy': 'Ớt chuông khỏe mạnh',
      'Pepper_bell_bacterial_spot': 'Ớt chuông - bệnh đốm vi khuẩn',
      'Tomato_Early_blight': 'Cà chua - bệnh héo sớm',
      'Potato_Early_blight': 'Khoai tây - bệnh héo sớm',
      'Potato_Late_blight': 'Khoai tây - bệnh héo muộn',
      'Tomato_Bacterial_spot': 'Cà chua - bệnh đốm vi khuẩn',
      'Tomato_Leaf_Mold': 'Cà chua - bệnh nấm lá',
      'Tomato_Septoria_leaf_spot': 'Cà chua - đốm lá Septoria',
      'Tomato_healthy': 'Cà chua khỏe mạnh',
      'Tomato_Late_blight': 'Cà chua - bệnh héo muộn',
      'Potato_healthy': 'Khoai tây khỏe mạnh',
      'Tomato_Target_Spot': 'Cà chua - đốm mục tiêu',
      'Tomato_Spider_mites': 'Cà chua - nhện đỏ',
      'Tomato_Yellow_Leaf_Curl_Virus': 'Cà chua - virus cuộn lá vàng',
      'Tomato_mosaic_virus': 'Cà chua - virus khảm',
    };

    return translations[disease] ?? disease;
  }
}

class CameraImage {
  final String imageUrl;
  final DateTime timestamp;
  final String disease;
  final double confidence;

  CameraImage({
    required this.imageUrl,
    required this.timestamp,
    required this.disease,
    required this.confidence,
  });
}
