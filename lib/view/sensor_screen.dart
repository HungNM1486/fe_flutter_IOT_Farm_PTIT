import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/models/sensor_model.dart';
import 'package:smart_farm/provider/sensor_provider.dart';
import 'package:smart_farm/res/imagesSF/AppImages.dart';
import 'package:smart_farm/theme/app_colors.dart';
import 'package:smart_farm/widget/bottom_bar.dart';
import 'package:smart_farm/widget/top_bar.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class SensorScreen extends StatefulWidget {
  @override
  _SensorScreenState createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();

    // Refresh dữ liệu vườn khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sensorProvider =
          Provider.of<SensorProvider>(context, listen: false);
      sensorProvider.refreshGardens();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String image(String type) {
    switch (type) {
      case 'Mưa':
        return AppImages.mua;
      case 'Nắng':
        return AppImages.sun;
      case 'Nhiều mây':
        return AppImages.may;
      default:
        return AppImages.sun;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final pix = size.width / 375;
    final sensorProvider = Provider.of<SensorProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            child: TopBar(
              title: "Thông tin cảm biến",
              isBack: false,
            ),
            top: 0,
            left: 0,
            right: 0,
          ),
          Positioned(
            top: 70 * pix,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: size.width,
              height: size.height - 70 * pix,
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: sensorProvider.gardens.isEmpty
                  ? _buildEmptyGardenState(pix)
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Garden selector tabs
                          _buildGardenTabs(pix, sensorProvider),

                          // Main weather page view
                          Container(
                            height: 520 * pix,
                            width: size.width,
                            child: PageView.builder(
                              itemCount: sensorProvider.gardens.length,
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final isCurrentPage = index == _currentPage;
                                return AnimatedContainer(
                                  key: ValueKey(
                                      'garden_${sensorProvider.gardens[index]['id']}'),
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeOutQuint,
                                  margin: EdgeInsets.only(
                                    top: isCurrentPage ? 0 : 20 * pix,
                                    bottom: isCurrentPage ? 0 : 20 * pix,
                                    left: 5 * pix,
                                    right: 5 * pix,
                                  ),
                                  child: _buildWeatherCard(
                                    context: context,
                                    garden: sensorProvider.gardens[index],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Connection indicator
                          _buildConnectionStatus(pix, sensorProvider),

                          SizedBox(height: 96 * pix),
                        ],
                      ),
                    ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Bottombar(type: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGardenState(double pix) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape_outlined,
            size: 80 * pix,
            color: Colors.white.withOpacity(0.7),
          ),
          SizedBox(height: 16 * pix),
          Text(
            'Chưa có vườn nào được tạo',
            style: TextStyle(
              fontSize: 18 * pix,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 8 * pix),
          Text(
            'Hãy tạo vườn trong mùa vụ hoạt động để theo dõi dữ liệu cảm biến',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14 * pix,
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 24 * pix),
          ElevatedButton.icon(
            onPressed: () {
              final sensorProvider =
                  Provider.of<SensorProvider>(context, listen: false);
              sensorProvider.refreshGardens();
            },
            icon: Icon(Icons.refresh),
            label: Text('Làm mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: EdgeInsets.symmetric(
                  horizontal: 20 * pix, vertical: 10 * pix),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(double pix, SensorProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * pix, vertical: 8 * pix),
      padding: EdgeInsets.symmetric(horizontal: 12 * pix, vertical: 8 * pix),
      decoration: BoxDecoration(
        color: provider.isConnected
            ? AppColors.statusGood.withOpacity(0.2)
            : AppColors.statusDanger.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20 * pix),
      ),
      child: Row(
        children: [
          Container(
            width: 8 * pix,
            height: 8 * pix,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: provider.isConnected
                  ? AppColors.statusGood
                  : AppColors.statusDanger,
            ),
          ),
          SizedBox(width: 8 * pix),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.connectionStatus,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12 * pix,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
              Text(
                'Broker: ${provider.broker}:${provider.port} ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10 * pix,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
              Text(
                'Topic: ${provider.mainTopic}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10 * pix,
                  fontFamily: 'BeVietnamPro',
                ),
              )
            ],
          ),
          if (!provider.isConnected && !provider.isConnecting) ...[
            SizedBox(width: 8 * pix),
            GestureDetector(
              onTap: provider.reconnect,
              child: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 16 * pix,
              ),
            ),
          ],
          Spacer(),
          // Cải tiến nút debug
          _buildDebugButton(pix),
        ],
      ),
    );
  }

  // Nút debug cải tiến
  Widget _buildDebugButton(double pix) {
    return GestureDetector(
      onTap: () => _showEnhancedDebugDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * pix, vertical: 4 * pix),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16 * pix),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bug_report,
              color: Colors.white,
              size: 16 * pix,
            ),
            SizedBox(width: 4 * pix),
            Text(
              'MQTT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * pix,
                fontWeight: FontWeight.w500,
                fontFamily: 'BeVietnamPro',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog debug nâng cao
  void _showEnhancedDebugDialog(BuildContext context) {
    final pix = MediaQuery.of(context).size.width / 375;
    final provider = Provider.of<SensorProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * pix),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            padding: EdgeInsets.all(16 * pix),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cài đặt MQTT',
                      style: TextStyle(
                        fontSize: 20 * pix,
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

                // Thông tin kết nối
                Container(
                  padding: EdgeInsets.all(8 * pix),
                  decoration: BoxDecoration(
                    color: provider.isConnected
                        ? AppColors.statusGood.withOpacity(0.1)
                        : AppColors.statusDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8 * pix),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8 * pix,
                        height: 8 * pix,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: provider.isConnected
                              ? AppColors.statusGood
                              : AppColors.statusDanger,
                        ),
                      ),
                      SizedBox(width: 8 * pix),
                      Text(
                        'Broker: ${provider.broker}:${provider.port} ',
                        style: TextStyle(
                          fontSize: 14 * pix,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16 * pix),

                // Cài đặt tần suất gửi dữ liệu
                Text(
                  'Tần suất gửi dữ liệu (ms)',
                  style: TextStyle(
                    fontSize: 16 * pix,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),

                SizedBox(height: 8 * pix),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIntervalButton(context, 5000, '5s', provider),
                    _buildIntervalButton(context, 10000, '10s', provider),
                    _buildIntervalButton(context, 30000, '30s', provider),
                    _buildIntervalButton(context, 60000, '1m', provider),
                  ],
                ),

                SizedBox(height: 16 * pix),

                // Hiệu chỉnh cảm biến
                ElevatedButton(
                  onPressed: () {
                    provider.calibrateMQ02();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đang hiệu chỉnh cảm biến khí...'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(
                        horizontal: 16 * pix, vertical: 8 * pix),
                  ),
                  child: Text(
                    'Hiệu chỉnh cảm biến khí',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                ),

                Spacer(),

                // Kết nối lại
                ElevatedButton(
                  onPressed: () {
                    provider.reconnect();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: Size(double.infinity, 48 * pix),
                  ),
                  child: Text(
                    'Kết nối lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'BeVietnamPro',
                      fontSize: 16 * pix,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntervalButton(BuildContext context, int interval, String label,
      SensorProvider provider) {
    return ElevatedButton(
      onPressed: () {
        provider.updateSendInterval(interval);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật tần suất gửi dữ liệu: $label'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'BeVietnamPro',
        ),
      ),
    );
  }

  Widget _buildGardenTabs(double pix, SensorProvider provider) {
    return Container(
      height: 30 * pix,
      margin: EdgeInsets.only(top: 10 * pix),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.gardens.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentPage;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8 * pix),
              padding: EdgeInsets.symmetric(horizontal: 16 * pix),
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30 * pix),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                provider.gardens[index]['name'],
                style: TextStyle(
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14 * pix,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard(
      {required BuildContext context, required Map<String, dynamic> garden}) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    final now = DateTime.now();
    final dateFormat = DateFormat('d MMMM, yyyy');
    final formattedDate = dateFormat.format(now);

    // Format thời gian cập nhật cuối
    String lastUpdatedText = "";
    if (garden['lastUpdated'] != null) {
      final lastUpdated = garden['lastUpdated'] as DateTime;
      lastUpdatedText =
          "Cập nhật lúc: ${DateFormat('HH:mm:ss').format(lastUpdated)}";
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Weather icon animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 2 * math.pi * 0.05,
                child: child,
              );
            },
            child: Image.asset(
              image(garden['weather']),
              width: 100 * pix,
              height: 100 * pix,
              fit: BoxFit.contain,
            ),
          ),

          // Main weather card with MQTT data
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16 * pix),
            padding: EdgeInsets.all(10 * pix),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24 * pix),
              color: Colors.white.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Garden info
                if (garden['description'] != null ||
                    garden['area'] != null) ...[
                  Container(
                    padding: EdgeInsets.all(8 * pix),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8 * pix),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (garden['description'] != null &&
                            garden['description'].toString().isNotEmpty)
                          Text(
                            garden['description'],
                            style: TextStyle(
                              fontSize: 12 * pix,
                              color: Colors.white,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        if (garden['area'] != null &&
                            garden['area'].toString().isNotEmpty)
                          Text(
                            'Diện tích: ${garden['area']}',
                            style: TextStyle(
                              fontSize: 12 * pix,
                              color: Colors.white,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10 * pix),
                ],

                // Date and last updated
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12 * pix,
                        color: Colors.white,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    if (garden['lastUpdated'] != null)
                      Text(
                        lastUpdatedText,
                        style: TextStyle(
                          fontSize: 12 * pix,
                          color: Colors.white.withOpacity(0.8),
                          fontFamily: 'BeVietnamPro',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 10 * pix),

                // Temperature display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${garden['temperature']}',
                      style: TextStyle(
                        fontSize: 50 * pix,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'BeVietnamPro',
                        height: 0.9,
                      ),
                    ),
                    Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 20 * pix,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10 * pix),

                // Weather condition from MQTT data
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * pix,
                    vertical: 5 * pix,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20 * pix),
                  ),
                  child: Text(
                    garden['weather'],
                    style: TextStyle(
                      fontSize: 14 * pix,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                ),

                SizedBox(height: 10 * pix),

                Divider(
                  color: Colors.white.withOpacity(0.3),
                  height: 10 * pix,
                  thickness: 1.5,
                ),

                // Weather metrics in grid - Hiển thị 3 thông số từ ESP32: nhiệt độ, độ ẩm, ánh sáng
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.thermostat,
                            value: '${garden['temperature']} °C',
                            label: 'Nhiệt độ',
                            pix: pix,
                            iconColor: AppColors.lightBlue,
                          ),
                        ),
                        SizedBox(width: 12 * pix),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.opacity,
                            value: '${garden['humidity']}%',
                            label: 'Độ ẩm',
                            pix: pix,
                            iconColor: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * pix),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.wb_sunny,
                            value: '${garden['light']} lux',
                            label: 'Ánh sáng',
                            pix: pix,
                            iconColor: AppColors.accentYellow,
                          ),
                        ),
                        SizedBox(width: 12 * pix),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.cloud,
                            value: '${garden['gas']} ppm',
                            label: 'Khí gas',
                            pix: pix,
                            iconColor: AppColors.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 56 * pix),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required double pix,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(10 * pix),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16 * pix),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10 * pix),
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20 * pix,
            ),
          ),
          SizedBox(height: 8 * pix),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * pix,
              fontWeight: FontWeight.bold,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 4 * pix),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12 * pix,
              fontFamily: 'BeVietnamPro',
            ),
          ),
        ],
      ),
    );
  }
}
