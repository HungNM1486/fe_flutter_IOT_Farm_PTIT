import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:smart_farm/utils/base_url.dart';

class PredictionResult {
  final String imageUrl;
  final String imageId;
  final String disease;
  final double probability;
  final String predictionId;
  final DateTime timestamp;

  PredictionResult({
    required this.imageUrl,
    required this.imageId,
    required this.disease,
    required this.probability,
    required this.predictionId,
    required this.timestamp,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      imageUrl: json['imageUrl'] ?? '',
      imageId: json['imageId'] ?? '',
      disease: json['disease'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
      predictionId: json['predictionId'] ?? '',
      timestamp: DateTime.now(),
    );
  }
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Callback cho prediction results
  Function(PredictionResult)? _onPredictionReceived;

  // Thêm callback cho notification
  Function(Map<String, dynamic>)? _onNotificationReceived;

  bool get isConnected => _isConnected;

  void connect() {
    if (_socket != null && _isConnected) return;

    try {
      _socket = IO.io(
        BaseUrl.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setTimeout(5000)
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        _isConnected = true;
        log('WebSocket connected successfully');
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        log('WebSocket disconnected');
      });

      _socket?.onError((error) {
        _isConnected = false;
        log('WebSocket error: $error');
      });

      _socket?.on('new_image', (data) {
        try {
          final predictionResult = PredictionResult.fromJson(data);
          _onPredictionReceived?.call(predictionResult);
          log('Received new prediction: ${predictionResult.disease}');
        } catch (e) {
          log('Error parsing prediction data: $e');
        }
      });

      _socket?.on('new_notification', (data) {
        try {
          log('Received new notification: ${data.toString()}');
          _onNotificationReceived?.call(data);
        } catch (e) {
          log('Error parsing notification data: $e');
        }
      });
    } catch (e) {
      log('WebSocket connection error: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void onPredictionReceived(Function(PredictionResult) callback) {
    _onPredictionReceived = callback;
  }

  // Thêm method này sau method onPredictionReceived:
  void onNotificationReceived(Function(Map<String, dynamic>) callback) {
    _onNotificationReceived = callback;
  }

  void clearCallbacks() {
    _onPredictionReceived = null;
    _onNotificationReceived = null;
  }
}
