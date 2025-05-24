import 'package:flutter/material.dart';
import 'package:smart_farm/res/imagesSF/AppImages.dart';
import 'package:smart_farm/view/detail_plant.dart';
import 'package:smart_farm/widget/bottom_bar.dart';
import 'package:smart_farm/widget/top_bar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/provider/plant_provider.dart';
import 'package:smart_farm/models/plant_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();

  // Danh sách cây trồng đã thu hoạch
  List<PlantModel> get harvestedPlants {
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
    return plantProvider.plants
        .where((plant) => plant.status == 'Đã thu hoạch')
        .toList();
  }

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
    searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Scaffold(
      body: Stack(
        children: [
          // Top Bar
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(
              title: "Lịch sử vụ mùa",
              isBack: false,
            ),
          ),

          // Main content
          Positioned(
            top: 60 * pix,
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
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.all(16 * pix),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm cây trồng',
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.white),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30 * pix),
                        ),
                        fillColor: Colors.white.withOpacity(0.2),
                        filled: true,
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(30 * pix),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(30 * pix),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),

                  // Danh sách cây đã thu hoạch
                  Expanded(
                    child: _buildHarvestedTab(),
                  ),
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
                child: Bottombar(type: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestedTab() {
    final pix = MediaQuery.of(context).size.width / 375;

    // Filter plants based on search
    final filteredPlants = searchController.text.isEmpty
        ? harvestedPlants
        : harvestedPlants
            .where((plant) =>
                plant.name
                    .toString()
                    .toLowerCase()
                    .contains(searchController.text.toLowerCase()) ||
                plant.address
                    .toString()
                    .toLowerCase()
                    .contains(searchController.text.toLowerCase()))
            .toList();

    if (filteredPlants.isEmpty) {
      return _buildEmptyState(
        icon: Icons.eco,
        message: 'Không tìm thấy cây trồng',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16 * pix, 0, 16 * pix, 60 * pix),
      itemCount: filteredPlants.length,
      itemBuilder: (context, index) {
        final plant = filteredPlants[index];
        return _buildHarvestedCard(plant: plant, pix: pix);
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    final pix = MediaQuery.of(context).size.width / 375;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80 * pix,
            color: Colors.white.withOpacity(0.7),
          ),
          SizedBox(height: 16 * pix),
          Text(
            message,
            style: TextStyle(
              fontSize: 18 * pix,
              color: Colors.white,
              fontFamily: 'BeVietnamPro',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestedCard({required PlantModel plant, required double pix}) {
    final plantDate = plant.startDate != null && plant.startDate != ""
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(plant.startDate!))
        : 'Chưa có dữ liệu';
    final harvestDate = plant.endDate != null && plant.endDate != ""
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(plant.endDate!))
        : 'Chưa có dữ liệu';
    final yieldValue = plant.unit ?? 'Chưa có dữ liệu';
    final qualityValue = plant.rating ?? 'Chưa có dữ liệu';
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16 * pix, vertical: 8 * pix),
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * pix)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPlantScreen(plantid: plant.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12 * pix),
        child: Padding(
          padding: EdgeInsets.all(16 * pix),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12 * pix),
                child: plant.image != null && plant.image != ""
                    ? Image.network(
                        plant.image!,
                        width: 60 * pix,
                        height: 60 * pix,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        AppImages.suhao,
                        width: 60 * pix,
                        height: 60 * pix,
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(width: 16 * pix),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name ?? '',
                      style: TextStyle(
                        fontSize: 18 * pix,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 4 * pix),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16 * pix, color: Colors.grey[600]),
                        SizedBox(width: 4 * pix),
                        Text(
                          plant.address ?? '',
                          style: TextStyle(
                              fontSize: 14 * pix, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4 * pix),
                    Row(
                      children: [
                        _buildInfoChip(
                            label: 'Ngày trồng',
                            value: plantDate,
                            icon: Icons.event,
                            pix: pix),
                        SizedBox(width: 8 * pix),
                        _buildInfoChip(
                            label: 'Ngày thu hoạch',
                            value: harvestDate,
                            icon: Icons.event_available,
                            pix: pix),
                      ],
                    ),
                    SizedBox(height: 4 * pix),
                    Row(
                      children: [
                        _buildInfoChip(
                            label: 'Sản lượng',
                            value: yieldValue,
                            icon: Icons.inventory,
                            pix: pix),
                        SizedBox(width: 8 * pix),
                        _buildInfoChip(
                            label: 'Chất lượng',
                            value: qualityValue,
                            icon: Icons.star,
                            pix: pix),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * pix),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10 * pix, vertical: 5 * pix),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15 * pix),
                ),
                child: Text(
                  plant.status ?? '',
                  style: TextStyle(
                      fontSize: 12 * pix,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
    required double pix,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * pix,
        vertical: 6 * pix,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8 * pix),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16 * pix,
            color: Colors.blue,
          ),
          SizedBox(width: 4 * pix),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10 * pix,
                    color: Colors.grey[600],
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12 * pix,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BeVietnamPro',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
