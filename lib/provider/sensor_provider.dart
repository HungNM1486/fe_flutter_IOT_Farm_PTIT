import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_farm/models/sensor_model.dart';
import 'package:smart_farm/provider/location_provider.dart';

class SensorProvider with ChangeNotifier {
  // MQTT Client
  MqttServerClient? _client;
  final String _broker = '103.6.234.189';
  final int _port = 1883;
  final String _username = 'admin';
  final String _password = 'admin';
  final String _mainTopic = 'iot/sensors/data';
  final String _statusTopic = 'iot/sensors/status';
  final String _configTopic = 'iot/sensors/config';

  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Chưa kết nối';

  StreamSubscription? _mqttSubscription;

  // Dữ liệu cảm biến
  Map<String, SensorData> _sensorDataMap = {};
  List<Map<String, dynamic>> _gardens = [];

  // Lịch sử dữ liệu
  Map<String, List<SensorData>> _sensorHistory = {};
  final int maxHistoryEntries = 50;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  Map<String, SensorData> get sensorDataMap => _sensorDataMap;
  List<Map<String, dynamic>> get gardens => _gardens;
  Map<String, List<SensorData>> get sensorHistory => _sensorHistory;
  String get broker => _broker;
  int get port => _port;
  String get username => _username;
  String get password => _password;
  String get mainTopic => _mainTopic;
  String get statusTopic => _statusTopic;
  String get configTopic => _configTopic;

  // Các provider khác
  LocationProvider? _locationProvider;

  SensorProvider() {
    // Khởi tạo danh sách vườn mặc định
    _initDefaultGardens();

    // Khởi tạo MQTT client
    _initMQTT();

    // Kiểm tra kết nối định kỳ
    Timer.periodic(Duration(seconds: 30), (timer) {
      _checkConnection();
    });
  }

  void setProviders(LocationProvider locationProvider) {
    _locationProvider = locationProvider;
    _updateGardensFromLocations();
  }

  void _initDefaultGardens() {
    _gardens = [
      {
        'id': 'default_garden',
        'name': 'Đang tải...',
        'weather': 'Đang cập nhật...',
        'temperature': 0,
        'humidity': 0,
        'light': 0,
        'gas': 0,
        'lastUpdated': null,
      },
    ];
  }

  Future<void> _updateGardensFromLocations() async {
    if (_locationProvider == null) return;

    // Lấy danh sách vườn từ _locationProvider
    final locations = _locationProvider!.locations;

    if (locations.isEmpty) {
      // Nếu không có vườn nào, giữ nguyên danh sách mặc định
      return;
    }

    // Cập nhật danh sách vườn
    _gardens = locations.map((location) {
      // Tìm dữ liệu cảm biến hiện có cho vườn này (nếu có)
      final existingGarden = _gardens.firstWhere(
        (garden) => garden['id'] == location.id,
        orElse: () => {
          'id': location.id,
          'name': location.name,
          'weather': 'Đang cập nhật...',
          'temperature': 0,
          'humidity': 0,
          'light': 0,
          'gas': 0,
          'lastUpdated': null,
        },
      );

      // Trả về vườn với tên cập nhật từ backend nhưng giữ nguyên dữ liệu cảm biến
      return {
        'id': location.id,
        'name': location.name,
        'description': location.description,
        'area': location.area,
        'weather': existingGarden['weather'],
        'temperature': existingGarden['temperature'],
        'humidity': existingGarden['humidity'],
        'light': existingGarden['light'],
        'gas': existingGarden['gas'],
        'lastUpdated': existingGarden['lastUpdated'],
      };
    }).toList();

    notifyListeners();
  }

  void refreshGardens() {
    _updateGardensFromLocations();
  }

  void _initMQTT() async {
    if (_isConnecting) return;

    _isConnecting = true;
    _connectionStatus = 'Đang kết nối...';
    notifyListeners();

    try {
      final clientId =
          'smart_farm_flutter_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient(_broker, clientId);
      _client!.port = _port;
      _client!.logging(on: kDebugMode);
      _client!.keepAlivePeriod = 30;
      _client!.autoReconnect = true;
      _client!.resubscribeOnAutoReconnect = true;
      _client!.setProtocolV311();
      _client!.onAutoReconnect = _onAutoReconnect;

      // Cấu hình kết nối
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillTopic('smart_farm/disconnect')
          .withWillMessage(json.encode({
            'device_id': 'mobile_app',
            'status': 'offline',
            'timestamp': DateTime.now().millisecondsSinceEpoch
          }))
          .startClean()
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain();

      // Thêm username và password
      connMessage.authenticateAs(_username, _password);

      _client!.connectionMessage = connMessage;

      // Xử lý callbacks
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.pongCallback = _pongCallback;

      // Kết nối tới server với timeout
      await _client!.connect().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Kết nối MQTT quá hạn');
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi kết nối MQTT: $e');
      }
      _cleanUpOnError();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _onAutoReconnect() {
    if (kDebugMode) {
      print('Đang tự động kết nối lại MQTT');
    }
    _connectionStatus = 'Đang kết nối lại...';
    _isConnected = false;
    notifyListeners();
  }

  void _checkConnection() {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected &&
        !_isConnecting) {
      reconnect();
    }
  }

  void _cleanUpOnError() {
    _isConnected = false;
    _connectionStatus = 'Lỗi kết nối';
    notifyListeners();

    try {
      _client?.disconnect();
    } catch (e) {
      // Bỏ qua lỗi khi disconnect
    }
  }

  void reconnect() async {
    if (_isConnecting) return;

    _isConnecting = true;
    _connectionStatus = 'Đang kết nối lại...';
    _isConnected = false;
    notifyListeners();

    try {
      // Hủy subscription cũ
      _mqttSubscription?.cancel();

      // Đảm bảo client ngắt kết nối sạch sẽ
      if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
        _client?.disconnect();
      }

      // Tạo mới client
      _initMQTT();
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi reconnect: $e');
      }
      _cleanUpOnError();
    }
  }

  void _onConnected() {
    if (kDebugMode) {
      print('Đã kết nối tới MQTT broker');
    }
    _isConnected = true;
    _connectionStatus = 'Đã kết nối';
    notifyListeners();

    // Subscribe tới topic
    _subscribeToTopics();

    // Bắt đầu lắng nghe messages
    _mqttSubscription = _client!.updates?.listen(_onMessage);
  }

  void _onDisconnected() {
    if (kDebugMode) {
      print('Ngắt kết nối MQTT');
    }
    _isConnected = false;
    _connectionStatus = 'Mất kết nối';
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    if (kDebugMode) {
      print('Đã subscribe topic: $topic');
    }
  }

  void _pongCallback() {
    if (kDebugMode) {
      print('Ping response từ broker');
    }
  }

  void _subscribeToTopics() {
    _client?.subscribe(_mainTopic, MqttQos.atLeastOnce);
    _client?.subscribe(_statusTopic, MqttQos.atLeastOnce);

    if (kDebugMode) {
      print('Đã đăng ký nhận dữ liệu từ topic: $_mainTopic, $_statusTopic');
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    try {
      final MqttPublishMessage recMess = event[0].payload as MqttPublishMessage;
      final String message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final String topic = event[0].topic;

      if (kDebugMode) {
        print('Nhận message từ topic $topic: $message');
      }

      // Xử lý dữ liệu từ topic chính
      if (topic == _mainTopic) {
        try {
          final data = json.decode(message);
          final deviceId = data['device_id'] ?? 'unknown';

          // Tạo đối tượng SensorData từ JSON
          final sensorData = SensorData.fromJson(data);

          // Lưu dữ liệu mới nhất
          _sensorDataMap[deviceId] = sensorData;

          // Lưu vào lịch sử
          if (!_sensorHistory.containsKey(deviceId)) {
            _sensorHistory[deviceId] = [];
          }

          _sensorHistory[deviceId]!.add(sensorData);

          // Giới hạn số lượng mục lưu trữ
          if (_sensorHistory[deviceId]!.length > maxHistoryEntries) {
            _sensorHistory[deviceId]!.removeAt(0);
          }

          // Cập nhật dữ liệu cho tất cả các vườn
          _updateAllGardens(sensorData);

          notifyListeners();
        } catch (e) {
          if (kDebugMode) {
            print('Lỗi parse message từ topic $topic: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi xử lý message MQTT: $e');
      }
    }
  }

  void _updateAllGardens(SensorData data) {
    final now = DateTime.now();

    for (var i = 0; i < _gardens.length; i++) {
      // Cập nhật trực tiếp dữ liệu cho vườn
      _gardens[i]['temperature'] = data.temperature.round();
      _gardens[i]['humidity'] = data.humidity.round();
      _gardens[i]['light'] = data.light.round();
      _gardens[i]['gas'] = data.gas.round();
      _gardens[i]['weather'] = data.predictWeather();
      _gardens[i]['lastUpdated'] = now;
    }

    notifyListeners();
  }

  // Gửi lệnh cấu hình tới ESP32
  void sendConfig(Map<String, dynamic> config) {
    if (!_isConnected) return;

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(json.encode(config));

      _client?.publishMessage(
        _configTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: false,
      );

      if (kDebugMode) {
        print('Đã gửi cấu hình: $config');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi gửi cấu hình: $e');
      }
    }
  }

  // Cập nhật tần suất gửi dữ liệu
  void updateSendInterval(int intervalMs) {
    sendConfig({'interval': intervalMs});
  }

  // Yêu cầu hiệu chỉnh cảm biến MQ02
  void calibrateMQ02() {
    sendConfig({'calibrate_mq02': true});
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();

    try {
      if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
        _client?.disconnect();
      }
    } catch (e) {
      // Bỏ qua lỗi khi disconnect
    }

    super.dispose();
  }
}
