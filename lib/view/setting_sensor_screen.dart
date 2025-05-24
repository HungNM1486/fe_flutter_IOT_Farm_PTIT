import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/provider/sensor_provider.dart';
import 'package:smart_farm/theme/app_colors.dart';
import 'package:smart_farm/widget/bottom_bar.dart';
import 'package:smart_farm/widget/top_bar.dart';

class SettingSensorScreen extends StatefulWidget {
  const SettingSensorScreen({Key? key}) : super(key: key);

  @override
  State<SettingSensorScreen> createState() => _SettingSensorScreenState();
}

class _SettingSensorScreenState extends State<SettingSensorScreen> {
  int _selectedInterval = 10000; // Mặc định 10s

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;
    final sensorProvider = Provider.of<SensorProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            child: TopBar(
              title: "Cài đặt cảm biến",
              isBack: true,
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
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16 * pix),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin kết nối
                    _buildConnectionInfo(pix, sensorProvider),

                    SizedBox(height: 24 * pix),

                    // Cài đặt tần suất gửi dữ liệu
                    _buildIntervalSettings(pix, sensorProvider),

                    SizedBox(height: 24 * pix),

                    // Hiệu chỉnh cảm biến
                    _buildSensorCalibration(pix, sensorProvider),

                    SizedBox(height: 24 * pix),

                    // Thông tin thiết bị
                    _buildDeviceInfo(pix, sensorProvider),
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

  Widget _buildConnectionInfo(double pix, SensorProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * pix),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * pix),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin kết nối',
              style: TextStyle(
                fontSize: 18 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
              ),
            ),
            SizedBox(height: 16 * pix),
            _buildInfoRow(
                'Trạng thái:',
                provider.connectionStatus,
                pix,
                provider.isConnected
                    ? AppColors.statusGood
                    : AppColors.statusDanger),
            SizedBox(height: 8 * pix),
            _buildInfoRow(
                'Broker:', '${provider.broker}:${provider.port}', pix),
            SizedBox(height: 8 * pix),
            _buildInfoRow('Topic chính:', provider.mainTopic, pix),
            SizedBox(height: 16 * pix),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isConnecting ? null : provider.reconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 12 * pix),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * pix),
                  ),
                ),
                child: Text(
                  provider.isConnecting ? 'Đang kết nối...' : 'Kết nối lại',
                  style: TextStyle(
                    fontSize: 16 * pix,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSettings(double pix, SensorProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * pix),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * pix),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tần suất gửi dữ liệu',
              style: TextStyle(
                fontSize: 18 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
              ),
            ),
            SizedBox(height: 16 * pix),
            Text(
              'Chọn thời gian giữa các lần gửi dữ liệu từ cảm biến:',
              style: TextStyle(
                fontSize: 14 * pix,
                fontFamily: 'BeVietnamPro',
              ),
            ),
            SizedBox(height: 16 * pix),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIntervalButton(context, 5000, '5 giây', pix, provider),
                _buildIntervalButton(context, 10000, '10 giây', pix, provider),
                _buildIntervalButton(context, 30000, '30 giây', pix, provider),
              ],
            ),
            SizedBox(height: 8 * pix),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIntervalButton(context, 60000, '1 phút', pix, provider),
                _buildIntervalButton(context, 300000, '5 phút', pix, provider),
                _buildIntervalButton(context, 600000, '10 phút', pix, provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalButton(BuildContext context, int interval, String label,
      double pix, SensorProvider provider) {
    bool isSelected = _selectedInterval == interval;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInterval = interval;
        });
        provider.updateSendInterval(interval);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật tần suất gửi dữ liệu: $label'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * pix, vertical: 8 * pix),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8 * pix),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderGrey,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14 * pix,
            fontFamily: 'BeVietnamPro',
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCalibration(double pix, SensorProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * pix),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * pix),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiệu chỉnh cảm biến',
              style: TextStyle(
                fontSize: 18 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
              ),
            ),
            SizedBox(height: 16 * pix),
            Text(
              'Hiệu chỉnh cảm biến khí MQ02 để đảm bảo độ chính xác. Quá trình này sẽ mất khoảng 20 giây.',
              style: TextStyle(
                fontSize: 14 * pix,
                fontFamily: 'BeVietnamPro',
              ),
            ),
            SizedBox(height: 16 * pix),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  provider.calibrateMQ02();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang hiệu chỉnh cảm biến khí...'),
                      backgroundColor: AppColors.primaryBlue,
                      duration: Duration(seconds: 20),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: EdgeInsets.symmetric(vertical: 12 * pix),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * pix),
                  ),
                ),
                child: Text(
                  'Bắt đầu hiệu chỉnh',
                  style: TextStyle(
                    fontSize: 16 * pix,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(double pix, SensorProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * pix),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * pix),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin thiết bị',
              style: TextStyle(
                fontSize: 18 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
              ),
            ),
            SizedBox(height: 16 * pix),
            _buildInfoRow('Thiết bị:', 'ESP32 Sensors', pix),
            SizedBox(height: 8 * pix),
            _buildInfoRow('ID:', 'ESP32_SENSORS_001', pix),
            SizedBox(height: 8 * pix),
            _buildInfoRow('Cảm biến:', 'DHT11, MQ02, Light Sensor', pix),
            SizedBox(height: 8 * pix),
            _buildInfoRow('Firmware:', 'v1.0.0', pix),
            SizedBox(height: 16 * pix),
            _buildSensorTable(pix),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorTable(double pix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin cảm biến',
          style: TextStyle(
            fontSize: 16 * pix,
            fontWeight: FontWeight.bold,
            fontFamily: 'BeVietnamPro',
          ),
        ),
        SizedBox(height: 8 * pix),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderGrey),
            borderRadius: BorderRadius.circular(8 * pix),
          ),
          child: Table(
            border: TableBorder.all(
              color: AppColors.borderGrey,
              width: 1,
              borderRadius: BorderRadius.circular(8 * pix),
            ),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(2),
            },
            children: [
              _buildTableRow(
                ['Cảm biến', 'Loại', 'Thông số'],
                isHeader: true,
                pix: pix,
              ),
              _buildTableRow(
                [
                  'Nhiệt độ',
                  'DHT11',
                  'Phạm vi: 0°C ~ 50°C\nĐộ chính xác: ±2°C'
                ],
                pix: pix,
              ),
              _buildTableRow(
                ['Độ ẩm', 'DHT11', 'Phạm vi: 20% ~ 90%\nĐộ chính xác: ±5%'],
                pix: pix,
              ),
              _buildTableRow(
                ['Ánh sáng', 'LDR', 'Phạm vi: 0 ~ 10000 lux'],
                pix: pix,
              ),
              _buildTableRow(
                [
                  'Khí gas',
                  'MQ02',
                  'Phạm vi: 300 ~ 10000 ppm\nKhí: LPG, Propane, Hydrogen'
                ],
                pix: pix,
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(List<String> cells,
      {bool isHeader = false, required double pix}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? AppColors.primaryGreen.withOpacity(0.1) : null,
      ),
      children: cells.map((cell) {
        return Padding(
          padding: EdgeInsets.all(8 * pix),
          child: Text(
            cell,
            style: TextStyle(
              fontSize: isHeader ? 14 * pix : 12 * pix,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'BeVietnamPro',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value, double pix,
      [Color? valueColor]) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14 * pix,
            fontWeight: FontWeight.w500,
            fontFamily: 'BeVietnamPro',
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(width: 8 * pix),
        Text(
          value,
          style: TextStyle(
            fontSize: 14 * pix,
            fontWeight: FontWeight.bold,
            fontFamily: 'BeVietnamPro',
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
