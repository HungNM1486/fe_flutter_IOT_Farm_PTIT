import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/provider/auth_provider.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:smart_farm/widget/bottom_bar.dart';
import 'package:smart_farm/widget/network_img.dart';
import 'package:smart_farm/widget/top_bar.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with TickerProviderStateMixin {
  final _baseUrl = BaseUrl.baseUrl;
  String selectedLanguage = 'Tiếng Việt'; // Ngôn ngữ mặc định
  bool weatherNotification = true; // Thông báo thời tiết
  bool careNotification = true; // Thông báo kế hoạch chăm sóc
  bool isDarkMode = false; // Chế độ tối
  XFile? image;
  final ImagePicker _picker = ImagePicker(); // Define the ImagePicker instance
  TextEditingController nameController = TextEditingController();

  final List<String> languageOptions = ['Tiếng Việt', 'Tiếng Anh'];
  late AnimationController _controller;
  late Animation<double> _animation;
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

    // Initialize data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {});
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
            bottom: 0,
            child: Container(
              width: size.width,
              height: size.height - 100 * pix,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff47BFDF), Color(0xff4A91FF)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),

          // Main content
          Positioned(
            top: 120 * pix,
            left: 16 * pix,
            right: 16 * pix,
            bottom: 16 * pix,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Thông tin cá nhân ',
                    child: _buildProfileSelector(pix),
                    pix: pix,
                  ),
                  SizedBox(height: 20 * pix),
                  _buildSection(
                    title: 'Thông tin ứng dụng',
                    child: _buildAppInfo(pix),
                    pix: pix,
                  ),
                  SizedBox(height: 80 * pix),
                ],
              ),
            ),
          ),
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

  Widget _buildProfileSelector(double pix) {
    return Consumer<AuthProvider>(builder: (context, userProvider, child) {
      if (userProvider.loading) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
      final user = userProvider.user;
      return Padding(
        padding: EdgeInsets.all(16 * pix),
        child: Row(
          children: [
            user?.avatar != ""
                ? ClipOval(
                    child: NetworkImageWidget(
                      url: "${_baseUrl}${user?.avatar}" ?? "",
                      width: 80 * pix,
                      height: 80 * pix,
                    ),
                  )
                : CircleAvatar(
                    radius: 40 * pix,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 40 * pix,
                      color: Colors.grey[600],
                    ),
                  ),
            SizedBox(width: 16 * pix),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.username ?? "Người dùng",
                    style: TextStyle(
                      fontSize: 18 * pix,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BeVietnamPro',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * pix),
                  Text(
                    user?.email ?? "Chưa có email",
                    style: TextStyle(
                      fontSize: 14 * pix,
                      color: Colors.grey[600],
                      fontFamily: 'BeVietnamPro',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 16 * pix),
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 24 * pix,
                color: Colors.blue,
              ),
              onPressed: () {
                setState(() {
                  image = null; // Reset image khi mở dialog
                  nameController.text = "";
                });
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setDialogState) {
                        return AlertDialog(
                          title: Text(
                            'Chỉnh sửa thông tin cá nhân',
                            style: TextStyle(
                              fontSize: 18 * pix,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  _pickImage(setDialogState);
                                },
                                child: CircleAvatar(
                                  radius: 40 * pix,
                                  backgroundColor: Colors.grey[300],
                                  child: image != null
                                      ? ClipOval(
                                          child: Image.file(
                                            File(image!.path),
                                            width: 80 * pix,
                                            height: 80 * pix,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : (user?.avatar != "" &&
                                              user?.avatar != null
                                          ? ClipOval(
                                              child: NetworkImageWidget(
                                                url:
                                                    "${_baseUrl}${user?.avatar}" ??
                                                        "",
                                                width: 80 * pix,
                                                height: 80 * pix,
                                              ),
                                            )
                                          : Container(
                                              width: 80 * pix,
                                              height: 80 * pix,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey[300],
                                              ),
                                              child: Icon(
                                                Icons.camera_alt,
                                                size: 40 * pix,
                                                color: Colors.grey[600],
                                              ),
                                            )),
                                ),
                              ),
                              SizedBox(height: 16 * pix),
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: 'Tên người dùng',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Đóng'),
                                ),
                                SizedBox(width: 8 * pix),
                                ElevatedButton(
                                  onPressed: () {
                                    _updateProfile();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: Text(
                                    'Lưu',
                                    style: TextStyle(color: Colors.white),
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
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required double pix,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16 * pix),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),
          child,
        ],
      ),
    );
  }

  Widget _buildAppInfo(double pix) {
    return Padding(
      padding: EdgeInsets.all(16 * pix),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ứng dụng: Smart Farm',
            style: TextStyle(
              fontSize: 16 * pix,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 8 * pix),
          Text(
            'Phiên bản: 1.0.0',
            style: TextStyle(
              fontSize: 14 * pix,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 8 * pix),
          Text(
            'Nhà phát triển: xAI',
            style: TextStyle(
              fontSize: 14 * pix,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 12 * pix),
          ElevatedButton(
            onPressed: () {
              // TODO: Điều hướng đến trang hỗ trợ hoặc liên hệ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Liên hệ hỗ trợ: support@x.ai'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(
                horizontal: 24 * pix,
                vertical: 12 * pix,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * pix),
              ),
            ),
            child: Text(
              'Liên hệ hỗ trợ',
              style: TextStyle(
                fontSize: 16 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
