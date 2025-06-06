import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/provider/alert_settings_provider.dart';
import 'package:smart_farm/provider/auth_provider.dart';
import 'package:smart_farm/provider/location_provider.dart';
import 'package:smart_farm/provider/notification_provider.dart';
import 'package:smart_farm/provider/plant_provider.dart';
import 'package:smart_farm/provider/sensor_provider.dart';
import 'package:smart_farm/provider/care_task_provider.dart';
import 'package:smart_farm/view/login_screen.dart';
import 'package:smart_farm/services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.microphone.request();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider()), // Thêm provider

        ChangeNotifierProvider(create: (_) => PlantProvider()),
        ChangeNotifierProvider(create: (_) => CareTaskProvider()),
        ChangeNotifierProvider(
            create: (_) => AlertSettingsProvider()), // Thêm provider
        ChangeNotifierProxyProvider<LocationProvider, SensorProvider>(
          create: (_) => SensorProvider(),
          update: (_, locationProvider, sensorProvider) {
            sensorProvider!.setProviders(locationProvider);
            return sensorProvider;
          },
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Khởi tạo WebSocket global
    WebSocketService().connect();
  }

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Farm App ',
        home: Loginscreen(),
      ),
    );
  }
}
