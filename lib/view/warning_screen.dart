import 'package:flutter/material.dart';
import 'package:smart_farm/res/imagesSF/AppImages.dart';
import 'package:smart_farm/view/setting_sensor_screen.dart';
import 'package:smart_farm/widget/bottom_bar.dart';
import 'package:smart_farm/widget/top_bar.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({Key? key}) : super(key: key);

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> weatherData = {};
  List<Map<String, dynamic>> plants = []; // Danh sách cây trồng từ dữ liệu

  // Danh sách cây trồng giả lập (có thể thay bằng dữ liệu thực tế từ backend)
  final List<Map<String, dynamic>> allPlants = [
    {
      "id": "1",
      "name": "Su hào",
      "image": AppImages.suhao,
      "status": "Đang tốt",
      "weatherPreference": "Mát mẻ, ẩm",
    },
    {
      "id": "2",
      "name": "Khoai tây",
      "image": AppImages.khoaitay,
      "status": "Cần chú ý",
      "weatherPreference": "Mát, khô",
    },
    {
      "id": "3",
      "name": "Súp lơ",
      "image": AppImages.supno,
      "status": "Đang tốt",
      "weatherPreference": "Mát mẻ, nhiều nước",
    },
  ];
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
    _fetchWeatherAndAnalyze();

    // Initialize data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  void _fetchWeatherAndAnalyze() {
    setState(() {
      _isLoading = true;
    });

    // Mô phỏng lấy dữ liệu thời tiết (có thể thay bằng API thực tế)
    Future.delayed(Duration(seconds: 1), () {
      weatherData = {
        "date": DateTime.now(),
        "temperature": 32, // Nhiệt độ (độ C)
        "humidity": 85, // Độ ẩm (%)
        "condition": "Nắng nóng, ẩm cao", // Điều kiện thời tiết
      };

      // Phân tích cây dựa trên thời tiết
      plants = _analyzePlants(weatherData);
      setState(() {
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> _analyzePlants(Map<String, dynamic> weather) {
    List<Map<String, dynamic>> beneficialPlants = [];
    List<Map<String, dynamic>> affectedPlants = [];

    for (var plant in allPlants) {
      bool isBeneficial = false;
      String warningMessage = '';

      // Logic phân tích dựa trên điều kiện thời tiết
      if (weather['temperature'] > 30 && weather['humidity'] > 80) {
        // Thời tiết nóng ẩm
        if (plant['weatherPreference'].contains('ẩm')) {
          isBeneficial = true;
        } else {
          warningMessage = 'Thời tiết nóng ẩm có thể gây sâu bệnh hoặc úng rễ.';
        }
      } else if (weather['temperature'] < 20 && weather['humidity'] > 70) {
        // Thời tiết mát ẩm
        if (plant['weatherPreference'].contains('Mát mẻ')) {
          isBeneficial = true;
        } else {
          warningMessage = 'Thời tiết mát ẩm có thể không phù hợp.';
        }
      } else if (weather['temperature'] > 25 && weather['humidity'] < 50) {
        // Thời tiết nóng khô
        if (plant['weatherPreference'].contains('khô')) {
          isBeneficial = true;
        } else {
          warningMessage = 'Thời tiết nóng khô có thể gây thiếu nước.';
        }
      }

      final plantData = Map<String, dynamic>.from(plant);
      plantData['warningMessage'] = warningMessage;

      if (isBeneficial) {
        beneficialPlants.add(plantData);
      } else if (warningMessage.isNotEmpty) {
        affectedPlants.add(plantData);
      }
    }

    return [
      {'title': 'Cây có lợi', 'plants': beneficialPlants},
      {'title': 'Cây bị ảnh hưởng xấu', 'plants': affectedPlants},
    ];
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
              title: "Cảnh báo thời tiết",
              isBack: true,
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
            top: 80 * pix,
            left: 16 * pix,
            right: 16 * pix,
            bottom: 16 * pix,
            child: _isLoading
                ? _buildLoadingIndicator()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: _buildActionButton(
                            icon: Icons.settings,
                            label: 'Cài đặt',
                            pix: pix,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingSensorScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16 * pix),
                        ...plants
                            .map((section) => _buildPlantSection(section, pix))
                            .toList(),
                        SizedBox(height: 20 * pix),
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
                child: Bottombar(type: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Đang phân tích thời tiết...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSection(Map<String, dynamic> section, double pix) {
    final plantsList = section['plants'] as List<Map<String, dynamic>>;
    return Container(
      margin: EdgeInsets.only(bottom: 16 * pix),
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
              section['title'],
              style: TextStyle(
                fontSize: 18 * pix,
                fontWeight: FontWeight.bold,
                fontFamily: 'BeVietnamPro',
                color: section['title'] == 'Cây có lợi'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),
          plantsList.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(16 * pix),
                  child: Text(
                    'Không có cây nào ${section['title'] == 'Cây có lợi' ? 'được hưởng lợi' : 'bị ảnh hưởng'} trong điều kiện này.',
                    style: TextStyle(
                      fontSize: 14 * pix,
                      color: Colors.grey[600],
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: plantsList.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  itemBuilder: (context, index) {
                    final plant = plantsList[index];
                    return _buildPlantItem(
                        plant, pix, section['title'] == 'Cây có lợi');
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPlantItem(
      Map<String, dynamic> plant, double pix, bool isBeneficial) {
    return ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16 * pix, vertical: 8 * pix),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8 * pix),
        child: Image.asset(
          plant['image'],
          width: 50 * pix,
          height: 50 * pix,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        plant['name'],
        style: TextStyle(
          fontSize: 16 * pix,
          fontWeight: FontWeight.w500,
          fontFamily: 'BeVietnamPro',
        ),
      ),
      subtitle:
          plant['warningMessage'] != null && plant['warningMessage'].isNotEmpty
              ? Text(
                  plant['warningMessage'],
                  style: TextStyle(
                    fontSize: 12 * pix,
                    color: Colors.red,
                    fontFamily: 'BeVietnamPro',
                  ),
                )
              : null,
      trailing: Icon(
        isBeneficial ? Icons.thumb_up : Icons.warning,
        color: isBeneficial ? Colors.green : Colors.red,
        size: 24 * pix,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required double pix,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * pix),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * pix,
          vertical: 8 * pix,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12 * pix),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24 * pix,
            ),
            SizedBox(height: 4 * pix),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * pix,
                fontFamily: 'BeVietnamPro',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
