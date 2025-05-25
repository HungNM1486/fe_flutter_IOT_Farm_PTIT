import 'package:flutter/material.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:smart_farm/view/detail_plant.dart';
import 'package:smart_farm/widget/top_bar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/provider/plant_provider.dart';
import 'package:smart_farm/models/plant_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadHarvestedPlants();
  }

  void _loadHarvestedPlants() {
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
    // Lấy cây đã thu hoạch (harvested = true)
    plantProvider.fetchPlantsByUser(harvested: true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(title: 'Lịch sử thu hoạch', isBack: true),
          ),
          Positioned(
            top: 70 * pix,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff47BFDF).withOpacity(0.5),
              ),
              child: Consumer<PlantProvider>(
                builder: (context, plantProvider, child) {
                  if (plantProvider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (plantProvider.plants.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 80 * pix,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16 * pix),
                          Text(
                            'Chưa có cây nào được thu hoạch',
                            style: TextStyle(
                              fontSize: 18 * pix,
                              color: Colors.grey[600],
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadHarvestedPlants();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.all(16 * pix),
                      itemCount: plantProvider.plants.length,
                      itemBuilder: (context, index) {
                        final plant = plantProvider.plants[index];
                        return _buildHarvestedPlantCard(plant, pix);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestedPlantCard(PlantModel plant, double pix) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * pix),
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
      child: Padding(
        padding: EdgeInsets.all(16 * pix),
        child: Row(
          children: [
            // Plant image
            Container(
              width: 80 * pix,
              height: 80 * pix,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * pix),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: _buildPlantImage(plant, pix),
            ),

            SizedBox(width: 16 * pix),

            // Plant info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name ?? 'Chưa đặt tên',
                    style: TextStyle(
                      fontSize: 16 * pix,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                  SizedBox(height: 4 * pix),

                  // Harvest status
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8 * pix, vertical: 4 * pix),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12 * pix),
                    ),
                    child: Text(
                      'Đã thu hoạch',
                      style: TextStyle(
                        fontSize: 12 * pix,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ),

                  SizedBox(height: 8 * pix),

                  // Harvest details
                  if (plant.unit?.isNotEmpty == true)
                    Row(
                      children: [
                        Icon(Icons.scale,
                            size: 14 * pix, color: Colors.grey[600]),
                        SizedBox(width: 4 * pix),
                        Text(
                          'Sản lượng: ${plant.unit}',
                          style: TextStyle(
                            fontSize: 13 * pix,
                            color: Colors.grey[600],
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                      ],
                    ),

                  if (plant.rating?.isNotEmpty == true)
                    Row(
                      children: [
                        Icon(Icons.star, size: 14 * pix, color: Colors.amber),
                        SizedBox(width: 4 * pix),
                        Text(
                          'Chất lượng: ${plant.rating}',
                          style: TextStyle(
                            fontSize: 13 * pix,
                            color: Colors.grey[600],
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                      ],
                    ),

                  // Harvest date
                  if (plant.endDate?.isNotEmpty == true)
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14 * pix, color: Colors.grey[600]),
                        SizedBox(width: 4 * pix),
                        Text(
                          'Thu hoạch: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(plant.endDate!))}',
                          style: TextStyle(
                            fontSize: 13 * pix,
                            color: Colors.grey[600],
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // View detail button
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, size: 16 * pix),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailPlantScreen(plantid: plant.id ?? ''),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantImage(PlantModel plant, double pix) {
    // Similar to detail_plant.dart image building logic
    String img = plant.image ?? "";
    bool sys = false;

    if (img.isNotEmpty && img.length > 1) {
      if (img[1] == 'd') {
        if (img.length >= 17) {
          img = img.substring(17);
          sys = true;
        }
      }
    }

    try {
      if (img.isNotEmpty) {
        if (sys) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12 * pix),
            child: Image.asset(
              img,
              width: 80 * pix,
              height: 80 * pix,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(pix),
            ),
          );
        } else {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12 * pix),
            child: Image.network(
              BaseUrl.baseUrl + img,
              width: 80 * pix,
              height: 80 * pix,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(pix),
            ),
          );
        }
      }
      return _buildPlaceholder(pix);
    } catch (e) {
      return _buildPlaceholder(pix);
    }
  }

  Widget _buildPlaceholder(double pix) {
    return Container(
      width: 80 * pix,
      height: 80 * pix,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12 * pix),
      ),
      child: Icon(
        Icons.eco,
        size: 32 * pix,
        color: Colors.grey[500],
      ),
    );
  }
}
