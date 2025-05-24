import 'package:flutter/material.dart';
import 'package:smart_farm/res/imagesSF/AppImages.dart';
import 'package:smart_farm/view/history_screen.dart';
import 'package:smart_farm/view/home_screen.dart';
import 'package:smart_farm/view/sensor_screen.dart';
import 'package:smart_farm/view/setting_screen.dart';
import 'package:smart_farm/view/warning_screen.dart';
import 'package:smart_farm/theme/app_colors.dart';

class Bottombar extends StatefulWidget {
  const Bottombar({super.key, required this.type});
  final int type;

  @override
  State<Bottombar> createState() => _BottombarState();
}

class _BottombarState extends State<Bottombar> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Container(
      height: 70 * pix,
      width: size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24 * pix),
          topRight: Radius.circular(24 * pix),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            image: AppImages.iconhome,
            label: 'Trang chủ',
            enabled: widget.type == 1,
          ),
          _buildActionButton(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SensorScreen()),
              );
            },
            image: AppImages.iconthom,
            label: 'Khí hậu',
            enabled: widget.type == 2,
          ),
          _buildActionButton(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            image: AppImages.iconeye,
            label: 'Lịch sử',
            enabled: widget.type == 3,
          ),
          _buildActionButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WarningScreen()),
              );
            },
            image: AppImages.iconnoti,
            label: 'Cảnh báo',
            enabled: widget.type == 4,
          ),
          _buildActionButton(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SettingScreen()),
              );
            },
            image: AppImages.iconsetting,
            label: 'Cài đặt',
            enabled: widget.type == 5,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String image,
    required String label,
    required bool enabled,
  }) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40 * pix,
            width: 40 * pix,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primaryGreen.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Image.asset(
                image,
                width: 24 * pix,
                height: 24 * pix,
                color: enabled ? AppColors.primaryGreen : AppColors.textGrey,
              ),
            ),
          ),
          SizedBox(height: 4 * pix),
          Text(
            label,
            style: TextStyle(
              fontSize: 12 * pix,
              color: enabled ? AppColors.primaryGreen : AppColors.textGrey,
              fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'BeVietnamPro',
            ),
          ),
        ],
      ),
    );
  }
}
