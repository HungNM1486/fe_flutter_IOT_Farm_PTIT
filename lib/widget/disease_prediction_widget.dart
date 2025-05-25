// lib/widget/disease_prediction_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_farm/services/websocket_service.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:intl/intl.dart';

class DiseasePredictionWidget extends StatefulWidget {
  final String plantId;

  const DiseasePredictionWidget({
    super.key,
    required this.plantId,
  });

  @override
  State<DiseasePredictionWidget> createState() =>
      _DiseasePredictionWidgetState();
}

class _DiseasePredictionWidgetState extends State<DiseasePredictionWidget>
    with AutomaticKeepAliveClientMixin {
  final WebSocketService _wsService = WebSocketService();
  List<PredictionResult> _predictions = [];
  bool _isConnected = false;
  Timer? _connectionTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
    _wsService.onNotificationReceived(_onNotificationReceived);
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _wsService.clearCallbacks(); // Đảm bảo clear callbacks trước
    super.dispose();
  }

  void _initWebSocket() {
    _wsService.connect();
    _wsService.onPredictionReceived(_onPredictionReceived);

    // Kiểm tra trạng thái kết nối định kỳ
    _connectionTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _isConnected = _wsService.isConnected;
        });
      }
    });
  }

  void _onNotificationReceived(Map<String, dynamic> data) {
    if (!mounted) return; // Kiểm tra mounted đầu tiên

    if (data['type'] == 'disease_detected') {
      _showDiseaseAlert(data['message']);
    }
  }

  void _showDiseaseAlert(String message) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          final pix = MediaQuery.of(context).size.width / 375;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16 * pix),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 24 * pix),
                SizedBox(width: 8 * pix),
                Text(
                  'Cảnh báo bệnh cây!',
                  style: TextStyle(
                    fontSize: 18 * pix,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            content: Container(
              padding: EdgeInsets.symmetric(vertical: 8 * pix),
              child: Text(
                message,
                style: TextStyle(fontSize: 16 * pix),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Đã hiểu', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      // Cũng kiểm tra mounted cho SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    });

    // Hiển thị SnackBar bổ sung
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: () {
            // Có thể navigate đến trang notification
          },
        ),
      ),
    );
  }

  void _onPredictionReceived(PredictionResult result) {
    if (!mounted) return; // Thêm kiểm tra mounted đầu tiên

    setState(() {
      _predictions.insert(0, result);
      if (_predictions.length > 10) {
        _predictions.removeRange(10, _predictions.length);
      }
    });

    _showPredictionNotification(result);
  }

  void _showPredictionNotification(PredictionResult result) {
    if (!mounted) return; // Thêm kiểm tra mounted

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Phát hiện: ${result.disease}\nĐộ chính xác: ${(result.probability * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getDiseaseColor(result.disease),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) _showDetailDialog(result);
          },
        ),
      ),
    );
  }

  Color _getDiseaseColor(String disease) {
    if (disease.toLowerCase().contains('healthy') ||
        disease.toLowerCase().contains('tốt')) {
      return Colors.green;
    } else if (disease.toLowerCase().contains('spot') ||
        disease.toLowerCase().contains('blight') ||
        disease.toLowerCase().contains('bệnh')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  void _showDetailDialog(PredictionResult result) {
    final pix = MediaQuery.of(context).size.width / 375;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * pix),
        ),
        child: Container(
          padding: EdgeInsets.all(20 * pix),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kết quả phân tích',
                    style: TextStyle(
                      fontSize: 18 * pix,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: 16 * pix),

              // Image
              Container(
                width: 200 * pix,
                height: 150 * pix,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12 * pix),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12 * pix),
                  child: Image.network(
                    BaseUrl.baseUrl + result.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported, size: 50 * pix),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16 * pix),

              // Disease info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16 * pix),
                decoration: BoxDecoration(
                  color: _getDiseaseColor(result.disease).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * pix),
                  border: Border.all(
                    color: _getDiseaseColor(result.disease).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bệnh phát hiện:',
                      style: TextStyle(
                        fontSize: 14 * pix,
                        color: Colors.grey[600],
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 4 * pix),
                    Text(
                      _translateDisease(result.disease),
                      style: TextStyle(
                        fontSize: 16 * pix,
                        fontWeight: FontWeight.bold,
                        color: _getDiseaseColor(result.disease),
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 12 * pix),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Độ chính xác:',
                          style: TextStyle(
                              fontSize: 14 * pix, color: Colors.grey[600]),
                        ),
                        Text(
                          '${(result.probability * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16 * pix,
                            fontWeight: FontWeight.bold,
                            color: _getDiseaseColor(result.disease),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * pix),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thời gian:',
                          style: TextStyle(
                              fontSize: 14 * pix, color: Colors.grey[600]),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(result.timestamp),
                          style: TextStyle(fontSize: 14 * pix),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16 * pix),

              // Recommendations
              if (!result.disease.toLowerCase().contains('healthy'))
                _buildRecommendations(pix, result.disease),

              SizedBox(height: 16 * pix),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Đóng'),
                    ),
                  ),
                  SizedBox(width: 12 * pix),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations(double pix, String disease) {
    List<String> recommendations = _getRecommendations(disease);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * pix),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12 * pix),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 18 * pix, color: Colors.blue),
              SizedBox(width: 8 * pix),
              Text(
                'Khuyến nghị xử lý:',
                style: TextStyle(
                  fontSize: 14 * pix,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontFamily: 'BeVietnamPro',
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * pix),
          ...recommendations
              .map((rec) => Padding(
                    padding: EdgeInsets.only(bottom: 4 * pix),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.blue[700])),
                        Expanded(
                          child: Text(
                            rec,
                            style: TextStyle(
                                fontSize: 13 * pix, fontFamily: 'BeVietnamPro'),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Container(
      width: size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * pix),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16 * pix),
            child: Row(
              children: [
                Icon(Icons.biotech, size: 24 * pix, color: Colors.green),
                SizedBox(width: 8 * pix),
                Expanded(
                  child: Text(
                    "Dự đoán bệnh cây (AI)",
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 18 * pix,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Connection status
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8 * pix, vertical: 4 * pix),
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12 * pix),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isConnected ? Icons.wifi : Icons.wifi_off,
                        size: 12 * pix,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4 * pix),
                      Text(
                        _isConnected ? 'Kết nối' : 'Mất kết nối',
                        style: TextStyle(
                          fontSize: 10 * pix,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),

          // Content
          if (_predictions.isEmpty)
            Container(
              padding: EdgeInsets.all(32 * pix),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_enhance,
                    size: 64 * pix,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 12 * pix),
                  Text(
                    'Chờ ảnh từ ESP32-CAM',
                    style: TextStyle(
                      fontSize: 16 * pix,
                      color: Colors.grey[600],
                      fontFamily: 'BeVietnamPro',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8 * pix),
                  Text(
                    'Hệ thống sẽ tự động phân tích khi có ảnh mới',
                    style: TextStyle(
                      fontSize: 14 * pix,
                      color: Colors.grey[500],
                      fontFamily: 'BeVietnamPro',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            // Recent predictions
            Container(
              height: 300 * pix,
              child: ListView.separated(
                padding: EdgeInsets.all(16 * pix),
                itemCount: _predictions.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: 12 * pix),
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return _buildPredictionCard(prediction, pix);
                },
              ),
            ),

          SizedBox(height: 16 * pix),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(PredictionResult prediction, double pix) {
    return GestureDetector(
      onTap: () => _showDetailDialog(prediction),
      child: Container(
        padding: EdgeInsets.all(12 * pix),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12 * pix),
          border: Border.all(
            color: _getDiseaseColor(prediction.disease).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Image thumbnail
            Container(
              width: 60 * pix,
              height: 60 * pix,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8 * pix),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8 * pix),
                child: Image.network(
                  BaseUrl.baseUrl + prediction.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child:
                        Icon(Icons.image, size: 30 * pix, color: Colors.grey),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12 * pix),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _translateDisease(prediction.disease),
                    style: TextStyle(
                      fontSize: 14 * pix,
                      fontWeight: FontWeight.bold,
                      color: _getDiseaseColor(prediction.disease),
                      fontFamily: 'BeVietnamPro',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * pix),
                  Text(
                    '${(prediction.probability * 100).toStringAsFixed(1)}% chính xác',
                    style: TextStyle(
                      fontSize: 12 * pix,
                      color: Colors.grey[600],
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                  SizedBox(height: 2 * pix),
                  Text(
                    DateFormat('HH:mm dd/MM').format(prediction.timestamp),
                    style: TextStyle(
                      fontSize: 11 * pix,
                      color: Colors.grey[500],
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16 * pix,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
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
      'Tomato_Septoria_leaf_spot': 'Cà chua - bệnh đốm lá Septoria',
      'Tomato_healthy': 'Cà chua khỏe mạnh',
      'Tomato_Late_blight': 'Cà chua - bệnh héo muộn',
      'Potato_healthy': 'Khoai tây khỏe mạnh',
      'Tomato_Target_Spot': 'Cà chua - bệnh đốm mục tiêu',
      'Tomato_Spider_mites': 'Cà chua - bệnh nhện đỏ',
      'Tomato_Yellow_Leaf_Curl_Virus': 'Cà chua - virus cuộn lá vàng',
      'Tomato_mosaic_virus': 'Cà chua - virus khảm',
    };

    return translations[disease] ?? disease;
  }

  List<String> _getRecommendations(String disease) {
    final recommendations = {
      'Pepper_bell_bacterial_spot': [
        'Phun thuốc diệt khuẩn Copper',
        'Tăng cường thoát nước',
        'Tránh tưới nước lên lá'
      ],
      'Tomato_Early_blight': [
        'Phun fungicide Chlorothalonil',
        'Cắt bỏ lá bị nhiễm',
        'Cải thiện thông gió'
      ],
      'Tomato_Bacterial_spot': [
        'Sử dụng thuốc chứa Copper',
        'Loại bỏ cây nhiễm bệnh',
        'Khử trùng dụng cụ'
      ],
      'Tomato_Late_blight': [
        'Phun Metalaxyl + Mancozeb',
        'Tăng khoảng cách trồng',
        'Tránh tưới buổi tối'
      ],
    };

    return recommendations[disease] ??
        [
          'Theo dõi sát sao tình trạng cây',
          'Tham khảo ý kiến chuyên gia',
          'Cải thiện điều kiện trồng trọt'
        ];
  }
}
