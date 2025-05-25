import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/provider/auth_provider.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:smart_farm/view/alert_screen.dart';
import 'package:smart_farm/view/camera_control_screen.dart';
import 'package:smart_farm/widget/bottom_bar.dart';
import 'package:smart_farm/widget/network_img.dart';
import 'package:smart_farm/widget/top_bar.dart';
import 'package:smart_farm/theme/app_colors.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with TickerProviderStateMixin {
  final _baseUrl = BaseUrl.baseUrl;
  XFile? image;
  final ImagePicker _picker = ImagePicker();
  TextEditingController nameController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        setState(() {
          image = pickedImage;
        });
        setDialogState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: ${e.toString()}'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _updateProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (image == null && nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh hoặc nhập tên người dùng'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    bool success = await authProvider.uploadUser(
      avatar: image != null ? File(image!.path) : null,
      username: nameController.text.isNotEmpty ? nameController.text : null,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thất bại'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {
      image = null;
      nameController.clear();
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Scaffold(
      body: Stack(
        children: [
          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(
              title: "Cài đặt",
              isBack: false,
            ),
          ),

          // Gradient background
          Positioned(
            top: 70 * pix,
            left: 0,
            right: 0,
            bottom: 70 * pix,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16 * pix),
                child: Column(
                  children: [
                    SizedBox(height: 20 * pix),

                    // Profile Section
                    _buildProfileSection(pix),
                    SizedBox(height: 20 * pix),

                    // System Settings Section
                    _buildSystemSection(pix),
                    SizedBox(height: 20 * pix),

                    // App Info Section
                    _buildAppInfoSection(pix),
                    SizedBox(height: 20 * pix),

                    // Logout Button
                    _buildLogoutButton(pix),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_animation),
                child: Bottombar(type: 5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(double pix) {
    return Consumer<AuthProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.loading) {
          return Center(child: CircularProgressIndicator());
        }

        final user = userProvider.user;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * pix),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20 * pix),
            child: Column(
              children: [
                // Avatar and basic info
                Row(
                  children: [
                    Stack(
                      children: [
                        user?.avatar != ""
                            ? ClipOval(
                                child: NetworkImageWidget(
                                  url: "${_baseUrl}${user?.avatar}" ?? "",
                                  width: 70,
                                  height: 70,
                                ),
                              )
                            : CircleAvatar(
                                radius: 35 * pix,
                                backgroundColor:
                                    AppColors.primaryGreen.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 35 * pix,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4 * pix),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 12 * pix,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16 * pix),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.username ?? "Người dùng",
                            style: TextStyle(
                              fontSize: 20 * pix,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'BeVietnamPro',
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4 * pix),
                          Text(
                            user?.email ?? "Chưa có email",
                            style: TextStyle(
                              fontSize: 14 * pix,
                              color: AppColors.textGrey,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8 * pix),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8 * pix),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 20 * pix,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      onPressed: () => _showEditProfileDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemSection(double pix) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * pix),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20 * pix),
            child: Text(
              'Hệ thống',
              style: TextStyle(
                fontSize: 18 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
                color: AppColors.textDark,
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.borderGrey),
          _buildSettingItem(
            pix,
            icon: Icons.notifications_active,
            iconColor: Colors.orange,
            title: 'Cài đặt cảnh báo',
            subtitle: 'Ngưỡng cảnh báo cảm biến',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlertSettingsScreen(),
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.borderGrey),
          _buildSettingItem(
            pix,
            icon: Icons.camera_alt,
            iconColor: Colors.green,
            title: 'Camera ESP32-CAM',
            subtitle: 'Điều khiển camera, chụp ảnh',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraControlScreen()),
              );
            },
          ),
          Divider(height: 1, color: AppColors.borderGrey),
          _buildSettingItem(
            pix,
            icon: Icons.language,
            iconColor: Colors.blue,
            title: 'Ngôn ngữ',
            subtitle: 'Tiếng Việt',
            onTap: () {
              // TODO: Language settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          Divider(height: 1, color: AppColors.borderGrey),
          _buildSettingItem(
            pix,
            icon: Icons.security,
            iconColor: Colors.purple,
            title: 'Bảo mật',
            subtitle: 'Đổi mật khẩu, xác thực 2 bước',
            onTap: () {
              // TODO: Security settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(double pix) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * pix),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20 * pix),
            child: Text(
              'Thông tin ứng dụng',
              style: TextStyle(
                fontSize: 18 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
                color: AppColors.textDark,
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.borderGrey),
          _buildSettingItem(
            pix,
            icon: Icons.info,
            iconColor: Colors.green,
            title: 'Smart Farm v1.0.0',
            subtitle: 'Ứng dụng quản lý nông trại thông minh',
            showArrow: false,
          ),
          Divider(height: 1, color: AppColors.borderGrey),
          _buildSettingItem(
            pix,
            icon: Icons.support_agent,
            iconColor: Colors.cyan,
            title: 'Hỗ trợ',
            subtitle: 'Liên hệ đội ngũ hỗ trợ',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Liên hệ hỗ trợ: support@smartfarm.com'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.borderGrey),
          _buildSettingItem(
            pix,
            icon: Icons.rate_review,
            iconColor: Colors.amber,
            title: 'Đánh giá ứng dụng',
            subtitle: 'Chia sẻ trải nghiệm của bạn',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cảm ơn bạn đã sử dụng ứng dụng!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    double pix, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20 * pix, vertical: 16 * pix),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10 * pix),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10 * pix),
              ),
              child: Icon(
                icon,
                size: 24 * pix,
                color: iconColor,
              ),
            ),
            SizedBox(width: 16 * pix),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16 * pix,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.textDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2 * pix),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13 * pix,
                        color: AppColors.textGrey,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                size: 16 * pix,
                color: AppColors.textGrey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(double pix) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Đăng xuất'),
              content: Text('Bạn có chắc chắn muốn đăng xuất?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.pop(context);
                    // Navigate to login screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child:
                      Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 16 * pix),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * pix),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white, size: 20 * pix),
            SizedBox(width: 8 * pix),
            Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 16 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    setState(() {
      image = null;
      nameController.text = "";
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final pix = MediaQuery.of(context).size.width / 375;
            final user = Provider.of<AuthProvider>(context, listen: false).user;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16 * pix),
              ),
              title: Text(
                'Chỉnh sửa thông tin',
                style: TextStyle(
                  fontSize: 20 * pix,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar picker
                  InkWell(
                    onTap: () => _pickImage(setDialogState),
                    child: Container(
                      width: 100 * pix,
                      height: 100 * pix,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      child: image != null
                          ? ClipOval(
                              child: Image.file(
                                File(image!.path),
                                width: 100 * pix,
                                height: 100 * pix,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (user?.avatar != "" && user?.avatar != null
                              ? ClipOval(
                                  child: NetworkImageWidget(
                                    url: "${_baseUrl}${user?.avatar}" ?? "",
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : Container(
                                  width: 100 * pix,
                                  height: 100 * pix,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        AppColors.primaryGreen.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 40 * pix,
                                    color: AppColors.primaryGreen,
                                  ),
                                )),
                    ),
                  ),
                  SizedBox(height: 20 * pix),

                  // Name input
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên người dùng',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12 * pix),
                      ),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Hủy'),
                      ),
                    ),
                    SizedBox(width: 8 * pix),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8 * pix),
                          ),
                        ),
                        child: Text(
                          'Lưu',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
