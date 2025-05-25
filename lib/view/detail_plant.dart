import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/models/plant_model.dart';
import 'package:smart_farm/provider/plant_provider.dart';
import 'package:smart_farm/provider/sensor_provider.dart'; // Added import
import 'package:smart_farm/res/imagesSF/AppImages.dart';
import 'package:smart_farm/utils/base_url.dart';
import 'package:smart_farm/widget/top_bar.dart';
import 'package:intl/intl.dart';
import 'package:smart_farm/models/care_task_model.dart';
import 'package:smart_farm/provider/care_task_provider.dart';
import 'package:smart_farm/widget/disease_prediction_widget.dart';
import 'package:smart_farm/services/websocket_service.dart';

class DetailPlantScreen extends StatefulWidget {
  final String plantid;
  const DetailPlantScreen({super.key, required this.plantid});

  @override
  DetailPlantScreenState createState() => DetailPlantScreenState();
}

class DetailPlantScreenState extends State<DetailPlantScreen> {
  TextEditingController noteController = TextEditingController();
  TextEditingController yieldController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final WebSocketService _wsService = WebSocketService();

  String sysImage = "";
  final _baseUrl = BaseUrl.baseUrl;
  late VoidCallback? _plantProviderListener;

  // Camera capture state
  bool _isCapturing = false;

  // Các loại công việc chăm sóc
  final List<String> careTaskTypes = [
    'Bón phân',
    'Tưới nước',
    'Phun thuốc',
    'Tỉa cành',
    'Thu hoạch',
    'Xử lý sâu bệnh'
  ];

  // Trạng thái cây - thay đổi để có giá trị mặc định
  String plantStatus = 'Đang tốt';
  String oldplantStatus = 'Đang tốt';
  final List<String> statusOptions = [
    'Đang tốt',
    'Cần chú ý',
    'Có vấn đề',
  ];

  late PlantProvider _plantProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _plantProvider = Provider.of<PlantProvider>(context, listen: false);
  }

  @override
  void dispose() {
    if (_plantProviderListener != null) {
      _plantProvider.removeListener(_plantProviderListener!);
    }
    _wsService.clearCallbacks();

    noteController.dispose();
    yieldController.dispose();
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _wsService.connect();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final careTaskProvider =
          Provider.of<CareTaskProvider>(context, listen: false);
      careTaskProvider.fetchCareTasks(widget.plantid);
    });
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);
      plantProvider.fetchPlantById(widget.plantid);

      _plantProviderListener = () {
        if (!plantProvider.loading && plantProvider.plant != null && mounted) {
          setState(() {
            final apiStatus = plantProvider.plant?.status ?? '';
            if (statusOptions.contains(apiStatus)) {
              plantStatus = apiStatus;
              oldplantStatus = apiStatus;
            } else {
              print('Status từ API không khớp với các lựa chọn: $apiStatus');
            }
          });
        }
      };

      plantProvider.addListener(_plantProviderListener!);
    });
  }

  // Camera capture function
  Future<void> _capturePhoto() async {
    setState(() => _isCapturing = true);

    try {
      final sensorProvider =
          Provider.of<SensorProvider>(context, listen: false);
      sensorProvider.sendCameraCommand("capture");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Đã gửi lệnh chụp ảnh đến ESP32-CAM'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gửi lệnh chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Reset capturing state after 3 seconds
    await Future.delayed(Duration(seconds: 3));
    if (mounted) {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: ${e.toString()}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chụp ảnh: ${e.toString()}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Lỗi khi chụp ảnh: $e');
    }
  }

  void _showDefaultImageSelector() {
    final pix = MediaQuery.of(context).size.width / 375;

    final List<Map<String, dynamic>> defaultImages = [
      {"image": AppImages.suhao, "name": "Su hào"},
      {"image": AppImages.khoaitay, "name": "Khoai tây"},
      {"image": AppImages.supno, "name": "Súp lơ"},
      {"image": AppImages.caitim, "name": "Cải tím"},
      {"image": AppImages.duachuot, "name": "Dưa chuột"},
      {"image": AppImages.salach, "name": "Sa lách"},
      {"image": AppImages.toi, "name": "Tỏi"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(20 * pix),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chọn ảnh mặc định',
                    style: TextStyle(
                      fontSize: 18 * pix,
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
              SizedBox(height: 16 * pix),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10 * pix,
                    mainAxisSpacing: 10 * pix,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: defaultImages.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          sysImage = defaultImages[index]['image'];
                          _selectedImage = null;
                          nameController.text = defaultImages[index]['name'];
                        });
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12 * pix),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12 * pix),
                                child: Image.asset(
                                  defaultImages[index]['image'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4 * pix),
                          Text(
                            defaultImages[index]['name'],
                            style: TextStyle(
                              fontSize: 12 * pix,
                              fontFamily: 'BeVietnamPro',
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final pix = MediaQuery.of(context).size.width / 375;
        return Container(
          padding: EdgeInsets.all(20 * pix),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20 * pix)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chọn ảnh',
                style: TextStyle(
                  fontSize: 18 * pix,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
              SizedBox(height: 20 * pix),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Chụp ảnh',
                    pix: pix,
                    onTap: () {
                      Navigator.pop(context);
                      _takePicture();
                    },
                  ),
                  _buildImageOptionButton(
                    icon: Icons.photo_library,
                    label: 'Thư viện',
                    pix: pix,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ],
              ),
              SizedBox(height: 20 * pix),
            ],
          ),
        );
      },
    );
  }

  Future<void> updatePlant() async {
    if (_selectedImage == null &&
        sysImage == "" &&
        nameController.text.isEmpty &&
        addressController.text.isEmpty &&
        noteController.text.isEmpty &&
        plantStatus == oldplantStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có thay đổi nào để cập nhật'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
    final result = await plantProvider.updatePlant(
      plantId: widget.plantid,
      name: nameController.text != "" ? nameController.text : null,
      image: _selectedImage != null ? File(_selectedImage!.path) : null,
      status: plantStatus == oldplantStatus ? null : plantStatus,
      note: noteController.text != "" ? noteController.text : null,
      address: addressController.text != "" ? addressController.text : null,
    );

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thành công'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm cây thất bại'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void reset() {
    setState(() {
      _selectedImage = null;
      sysImage = "";
      nameController.clear();
      noteController.clear();
      plantStatus = 'Đang tốt';
      oldplantStatus = 'Đang tốt';
      yieldController.clear();
      addressController.clear();
    });
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
            child: TopBar(title: 'Chi tiết cây trồng', isBack: true),
          ),
          Positioned(
            top: 70 * pix,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: size.width,
              height: size.height - 100 * pix,
              decoration: BoxDecoration(
                color: const Color(0xff47BFDF).withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: 80 * pix,
            left: 16 * pix,
            right: 16 * pix,
            bottom: 0,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPlantInfoSection(context),
                  SizedBox(height: 20 * pix),
                  plantStatus != 'Đã thu hoạch'
                      ? _buildCarePlanSection(context)
                      : SizedBox(),
                  SizedBox(height: 20 * pix),
                  // Added Camera Control Section
                  plantStatus != 'Đã thu hoạch'
                      ? _buildCameraControlSection(context)
                      : SizedBox(),
                  SizedBox(height: 20 * pix),
                  plantStatus != 'Đã thu hoạch'
                      ? _buildDiseasePredictionSection(context)
                      : SizedBox(),
                  SizedBox(height: 36 * pix),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // New Camera Control Section
  Widget _buildCameraControlSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Container(
      width: size.width,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_enhance, size: 24 * pix, color: Colors.blue),
                SizedBox(width: 8 * pix),
                Text(
                  'Điều khiển Camera ESP32-CAM',
                  style: TextStyle(
                    fontSize: 18 * pix,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * pix),

            // Camera capture button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _capturePhoto,
                icon: _isCapturing
                    ? SizedBox(
                        width: 20 * pix,
                        height: 20 * pix,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.camera_alt, size: 20 * pix),
                label: Text(
                  _isCapturing ? 'Đang chụp...' : 'Chụp ảnh ngay',
                  style: TextStyle(
                    fontSize: 16 * pix,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12 * pix),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * pix),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12 * pix),

            // Info text
            Container(
              padding: EdgeInsets.all(12 * pix),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8 * pix),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16 * pix, color: Colors.blue),
                  SizedBox(width: 8 * pix),
                  Expanded(
                    child: Text(
                      'ESP32-CAM sẽ chụp ảnh và tự động phân tích bệnh cây bằng AI',
                      style: TextStyle(
                        fontSize: 13 * pix,
                        color: Colors.blue[700],
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarePlanSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Consumer<CareTaskProvider>(
        builder: (context, careTaskProvider, child) {
      if (careTaskProvider.loading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return Container(
        width: size.width,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kế hoạch chăm sóc',
                    style: TextStyle(
                      fontSize: 18 * pix,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: Colors.green,
                      size: 28 * pix,
                    ),
                    onPressed: () {
                      _showAddCareTaskDialog(context, pix);
                    },
                  ),
                ],
              ),
            ),
            Divider(
                height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),
            if (careTaskProvider.tasks.isEmpty)
              Padding(
                padding: EdgeInsets.all(16 * pix),
                child: Text(
                  'Chưa có công việc chăm sóc nào',
                  style: TextStyle(fontSize: 15 * pix, color: Colors.grey[600]),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: careTaskProvider.tasks.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.withOpacity(0.2),
                ),
                itemBuilder: (context, index) {
                  final task = careTaskProvider.tasks[index];
                  return ListTile(
                    leading: Icon(_getTaskIcon(task.type),
                        color: _getTaskColor(task.type)),
                    title: Text(
                      task.name,
                      style: TextStyle(
                          fontSize: 16 * pix, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Loại: ${task.type}',
                            style: TextStyle(fontSize: 13 * pix)),
                        Text(
                            'Ngày: ${DateFormat('dd/MM/yyyy').format(task.scheduledDate)}',
                            style: TextStyle(fontSize: 13 * pix)),
                        if (task.note.isNotEmpty)
                          Text('Ghi chú: ${task.note}',
                              style: TextStyle(
                                  fontSize: 13 * pix, color: Colors.grey[700])),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            _showEditCareTaskDialog(context, pix, task);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Xác nhận xóa'),
                                content: Text(
                                    'Bạn có chắc chắn muốn xóa công việc này?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: Text('Xóa',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await Provider.of<CareTaskProvider>(context,
                                      listen: false)
                                  .deleteCareTask(widget.plantid, task.id);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  void _showAddCareTaskDialog(BuildContext context, double pix) {
    String selectedType = careTaskTypes[0];
    TextEditingController nameController = TextEditingController();
    TextEditingController noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thêm công việc chăm sóc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Tên công việc'),
                ),
                SizedBox(height: 12 * pix),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: 'Loại công việc'),
                  items: careTaskTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) selectedType = newValue;
                  },
                ),
                SizedBox(height: 12 * pix),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(labelText: 'Ghi chú'),
                ),
                SizedBox(height: 12 * pix),
                Row(
                  children: [
                    Text('Ngày thực hiện: ',
                        style: TextStyle(fontSize: 14 * pix)),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                        }
                      },
                      child:
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await Provider.of<CareTaskProvider>(context, listen: false)
                    .addCareTask(
                  widget.plantid,
                  nameController.text,
                  selectedType,
                  selectedDate,
                  noteController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditCareTaskDialog(
      BuildContext context, double pix, CareTaskModel task) {
    String selectedType = task.type;
    TextEditingController nameController =
        TextEditingController(text: task.name);
    TextEditingController noteController =
        TextEditingController(text: task.note);
    DateTime selectedDate = task.scheduledDate;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chỉnh sửa công việc chăm sóc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Tên công việc'),
                ),
                SizedBox(height: 12 * pix),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: 'Loại công việc'),
                  items: careTaskTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) selectedType = newValue;
                  },
                ),
                SizedBox(height: 12 * pix),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(labelText: 'Ghi chú'),
                ),
                SizedBox(height: 12 * pix),
                Row(
                  children: [
                    Text('Ngày thực hiện: ',
                        style: TextStyle(fontSize: 14 * pix)),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                        }
                      },
                      child:
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await Provider.of<CareTaskProvider>(context, listen: false)
                    .updateCareTask(
                  widget.plantid,
                  task.id,
                  name: nameController.text,
                  type: selectedType,
                  scheduledDate: selectedDate,
                  note: noteController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlantInfoSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Consumer<PlantProvider>(builder: (context, plantProvider, child) {
      if (plantProvider.loading || plantProvider.plant == null) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      final plant = plantProvider.plant!;
      return Container(
        width: size.width,
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
            _buildPlantHeader(pix, plant),
            Divider(
                height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),
            _buildStatusSection(pix, plant),
            _buildPlantingDateSection(pix, plant),
            _buildLocationInfoSection(pix, plant),
            if (plant.status == 'Đã thu hoạch')
              _buildHarvestInfoSection(pix, plant),
            _buildNotesSection(pix, plant),
            plant.status != "Đã thu hoạch"
                ? _buildActionButtons(pix, plant)
                : SizedBox(),
            SizedBox(height: 16 * pix),
            _buildDeletePlantButton(context, pix, plant),
          ],
        ),
      );
    });
  }

  Widget _buildPlantHeader(double pix, PlantModel plant) {
    return Padding(
      padding: EdgeInsets.all(16 * pix),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: plant.status != 'Đã thu hoạch'
                ? () => _showImageOptions()
                : null,
            child: Container(
              width: 100 * pix,
              height: 100 * pix,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * pix),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildPlantImage(pix, 100, plant),
            ),
          ),
          SizedBox(width: 16 * pix),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name ?? 'Chưa đặt tên',
                  style: TextStyle(
                    fontSize: 22 * pix,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff165598),
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
                SizedBox(height: 8 * pix),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16 * pix,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4 * pix),
                    Text(
                      plant.address ?? 'Chưa có địa chỉ',
                      style: TextStyle(
                        fontSize: 14 * pix,
                        color: Colors.grey[600],
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * pix),
                if (plantStatus != 'Đã thu hoạch')
                  OutlinedButton.icon(
                    icon: Icon(Icons.edit, size: 16 * pix),
                    label: Text(
                      'Chỉnh sửa',
                      style: TextStyle(
                        fontSize: 14 * pix,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * pix),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * pix,
                        vertical: 6 * pix,
                      ),
                    ),
                    onPressed: () {
                      _showEditPlantInfoDialog();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPlantInfoDialog() {
    final pix = MediaQuery.of(context).size.width / 375;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Chỉnh sửa thông tin',
            style: TextStyle(
              fontSize: 18 * pix,
              fontWeight: FontWeight.bold,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên cây',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16 * pix),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlantImage(double pix, double size, PlantModel plant) {
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
      if (_selectedImage != null) {
        return FutureBuilder(
          future: _selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12 * pix),
                child: Image.memory(
                  snapshot.data!,
                  width: size * pix,
                  height: size * pix,
                  fit: BoxFit.cover,
                ),
              );
            }
            return _buildPlaceholderImage(pix, size);
          },
        );
      }

      if (img.isNotEmpty) {
        if (sys) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12 * pix),
            child: Image.asset(
              img,
              width: size * pix,
              height: size * pix,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Lỗi hiển thị ảnh asset: $error');
                return _buildPlaceholderImage(pix, size);
              },
            ),
          );
        } else {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12 * pix),
            child: Image.network(
              _baseUrl + img,
              width: size * pix,
              height: size * pix,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Lỗi hiển thị ảnh network: $error');
                return _buildPlaceholderImage(pix, size);
              },
            ),
          );
        }
      }

      if (plant.sysImg != null && plant.sysImg!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12 * pix),
          child: Image.asset(
            plant.sysImg!,
            width: size * pix,
            height: size * pix,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Lỗi hiển thị sysImg: $error');
              return _buildPlaceholderImage(pix, size);
            },
          ),
        );
      }

      return _buildPlaceholderImage(pix, size);
    } catch (e) {
      debugPrint('Lỗi hiển thị ảnh: $e');
      return _buildPlaceholderImage(pix, size);
    }
  }

  Widget _buildPlaceholderImage(double pix, double sz) {
    return Container(
      width: sz * pix,
      height: sz * pix,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12 * pix),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 32 * pix,
            color: Colors.grey[500],
          ),
          SizedBox(height: 8 * pix),
          Text(
            'Thêm ảnh',
            style: TextStyle(
              fontSize: 14 * pix,
              color: Colors.grey[500],
              fontFamily: 'BeVietnamPro',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(double pix, PlantModel plant) {
    return Padding(
      padding: EdgeInsets.all(16 * pix),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trạng thái:',
            style: TextStyle(
              fontSize: 16 * pix,
              fontWeight: FontWeight.bold,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 8 * pix),
          plant.status != "Đã thu hoạch"
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * pix),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8 * pix),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: statusOptions.contains(plantStatus)
                          ? plantStatus
                          : statusOptions[0],
                      isExpanded: true,
                      items: statusOptions.map((String value) {
                        Color statusColor;
                        if (value == 'Đang tốt') {
                          statusColor = Colors.green;
                        } else if (value == 'Cần chú ý') {
                          statusColor = Colors.orange;
                        } else if (value == 'Có vấn đề') {
                          statusColor = Colors.red;
                        } else {
                          statusColor = Colors.blue;
                        }

                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Container(
                                width: 12 * pix,
                                height: 12 * pix,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8 * pix),
                              Text(
                                value,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            plantStatus = newValue;
                          });
                        }
                      },
                    ),
                  ),
                )
              : Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * pix,
                    vertical: 10 * pix,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8 * pix),
                  ),
                  child: Text(
                    plant.status ?? "",
                    style: TextStyle(
                        fontSize: 16 * pix,
                        fontFamily: 'BeVietnamPro',
                        color: Colors.green),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPlantingDateSection(double pix, PlantModel plant) {
    return Padding(
      padding: EdgeInsets.all(16 * pix),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ngày trồng:',
            style: TextStyle(
              fontSize: 16 * pix,
              fontWeight: FontWeight.bold,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 8 * pix),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày bắt đầu:',
                      style: TextStyle(
                        fontSize: 14 * pix,
                        color: Colors.grey[600],
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 4 * pix),
                    Text(
                      plant.startDate != ""
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(plant.startDate!))
                          : 'Chưa có dữ liệu',
                      style: TextStyle(
                        fontSize: 16 * pix,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày kết thúc:',
                      style: TextStyle(
                        fontSize: 14 * pix,
                        color: Colors.grey[600],
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 4 * pix),
                    Text(
                      (plant.endDate != "" && plant.endDate != plant.startDate)
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(plant.endDate!))
                          : 'Chưa có dữ liệu',
                      style: TextStyle(
                        fontSize: 16 * pix,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestInfoSection(double pix, PlantModel plant) {
    return Padding(
      padding: EdgeInsets.all(16 * pix),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin thu hoạch:',
            style: TextStyle(
              fontSize: 16 * pix,
              fontWeight: FontWeight.bold,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 8 * pix),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày thu hoạch:',
                      style: TextStyle(
                        fontSize: 14 * pix,
                        color: Colors.grey[600],
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 4 * pix),
                    Text(
                      plant.endDate != ""
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(plant.endDate!))
                          : 'Chưa có dữ liệu',
                      style: TextStyle(
                        fontSize: 16 * pix,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * pix),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sản lượng:',
                      style: TextStyle(
                        fontSize: 14 * pix,
                        color: Colors.grey[600],
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 4 * pix),
                    Text(
                      (plant.yieldAmount != null &&
                              plant.yieldAmount! > 0 &&
                              plant.unit != null)
                          ? '${plant.yieldAmount} ${plant.unit}'
                          : 'Chưa có dữ liệu',
                      style: TextStyle(
                        fontSize: 16 * pix,
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chất lượng:',
                      style: TextStyle(
                        fontSize: 14 * pix,
                        color: Colors.grey[600],
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 4 * pix),
                    Text(
                      plant.rating != null && plant.rating!.isNotEmpty
                          ? plant.rating!
                          : 'Chưa có dữ liệu',
                      style: TextStyle(
                        fontSize: 16 * pix,
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.w600,
                        color: _getQualityColor(plant.rating),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (plant.qualityDescription != null &&
              plant.qualityDescription!.isNotEmpty) ...[
            SizedBox(height: 12 * pix),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mô tả chất lượng:',
                  style: TextStyle(
                    fontSize: 14 * pix,
                    color: Colors.grey[600],
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
                SizedBox(height: 4 * pix),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12 * pix),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8 * pix),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Text(
                    plant.qualityDescription!,
                    style: TextStyle(
                      fontSize: 14 * pix,
                      fontFamily: 'BeVietnamPro',
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getQualityColor(String? rating) {
    if (rating == null || rating.isEmpty) return Colors.grey;

    switch (rating) {
      case 'Tốt':
        return Colors.green[700]!;
      case 'Trung bình':
        return Colors.orange[700]!;
      case 'Kém':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildNotesSection(double pix, PlantModel plant) {
    noteController.text = plant.note ?? '';
    return Padding(
      padding: EdgeInsets.all(16 * pix),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú:',
            style: TextStyle(
              fontSize: 16 * pix,
              fontWeight: FontWeight.bold,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 8 * pix),
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú về cây trồng...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * pix),
              ),
              contentPadding: EdgeInsets.all(16 * pix),
            ),
            maxLines: 3,
            onChanged: (value) {
              plant.note = value;
            },
            enabled: plantStatus != 'Đã thu hoạch',
          ),
        ],
      ),
    );
  }

  void _showHarvestDialog(PlantModel plant, double pix) {
    final TextEditingController yieldAmountController = TextEditingController();
    final TextEditingController yieldUnitController =
        TextEditingController(text: 'kg');
    final TextEditingController qualityRatingController =
        TextEditingController();
    final TextEditingController qualityDescriptionController =
        TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Xác nhận thu hoạch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: yieldAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Sản lượng (số)'),
                ),
                SizedBox(height: 12 * pix),
                TextField(
                  controller: yieldUnitController,
                  decoration:
                      InputDecoration(labelText: 'Đơn vị (kg, tấn, tạ)'),
                ),
                SizedBox(height: 12 * pix),
                DropdownButtonFormField<String>(
                  value: null,
                  decoration: InputDecoration(labelText: 'Chất lượng'),
                  items: ['Tốt', 'Trung bình', 'Kém'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    qualityRatingController.text = newValue ?? '';
                  },
                ),
                SizedBox(height: 12 * pix),
                TextField(
                  controller: qualityDescriptionController,
                  decoration: InputDecoration(labelText: 'Mô tả chất lượng'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final yieldAmount = yieldAmountController.text.trim();
                final yieldUnit = yieldUnitController.text.trim();
                final qualityRating = qualityRatingController.text.trim();
                final qualityDescription =
                    qualityDescriptionController.text.trim();
                if (yieldAmount.isEmpty ||
                    yieldUnit.isEmpty ||
                    qualityRating.isEmpty) return;
                final plantProvider =
                    Provider.of<PlantProvider>(context, listen: false);
                await plantProvider.updatePlant(
                  plantId: plant.id ?? '',
                  status: 'Đã thu hoạch',
                  yieldAmount: yieldAmount,
                  yieldUnit: yieldUnit,
                  qualityRating: qualityRating,
                  qualityDescription: qualityDescription,
                );
                Navigator.pop(context);
                Provider.of<PlantProvider>(context, listen: false)
                    .fetchPlantById(plant.id ?? '');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(double pix, PlantModel plant) {
    return Padding(
      padding: EdgeInsets.all(16 * pix),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                updatePlant();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12 * pix),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * pix),
                ),
              ),
              child: Text(
                'Lưu thay đổi',
                style: TextStyle(
                  fontSize: 16 * pix,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BeVietnamPro',
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16 * pix),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _showHarvestDialog(plant, pix);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 12 * pix),
                side: BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * pix),
                ),
              ),
              child: Text(
                'Đã thu hoạch',
                style: TextStyle(
                  fontSize: 16 * pix,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BeVietnamPro',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOptionButton({
    required IconData icon,
    required String label,
    required double pix,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * pix),
      child: Container(
        width: 80 * pix,
        padding: EdgeInsets.all(16 * pix),
        decoration: BoxDecoration(
          color: (color ?? Colors.green).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12 * pix),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32 * pix,
              color: color ?? Colors.green,
            ),
            SizedBox(height: 8 * pix),
            Text(
              label,
              style: TextStyle(
                fontSize: 12 * pix,
                fontWeight: FontWeight.w500,
                fontFamily: 'BeVietnamPro',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseasePredictionSection(BuildContext context) {
    return DiseasePredictionWidget(plantId: widget.plantid);
  }

  Widget _buildLocationInfoSection(double pix, PlantModel plant) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * pix, vertical: 4 * pix),
      child: Row(
        children: [
          Icon(Icons.place, size: 16 * pix, color: Colors.blueGrey),
          SizedBox(width: 6 * pix),
          Expanded(
            child: Text(
              'Mã vị trí: ${plant.locationId ?? "Chưa có"}',
              style: TextStyle(fontSize: 14 * pix, color: Colors.blueGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletePlantButton(
      BuildContext context, double pix, PlantModel plant) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * pix, vertical: 12 * pix),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(16 * pix),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16 * pix),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 28 * pix),
                    SizedBox(width: 8 * pix),
                    Text('Xác nhận xóa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Text('Bạn có chắc chắn muốn xóa cây này không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child:
                        Text('Hủy', style: TextStyle(color: Colors.grey[700])),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * pix),
                      ),
                    ),
                    child: Text('Xóa', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              final plantProvider =
                  Provider.of<PlantProvider>(context, listen: false);
              final result = await plantProvider.deletePlant(plant.id ?? "");
              if (result) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa cây thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Xóa cây thất bại'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18 * pix, horizontal: 0),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16 * pix),
              border: Border.all(color: Colors.red.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.07),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever_rounded,
                    color: Colors.red, size: 28 * pix),
                SizedBox(width: 10 * pix),
                Text(
                  'XÓA CÂY NÀY',
                  style: TextStyle(
                    fontSize: 18 * pix,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BeVietnamPro',
                    color: Colors.red.shade700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTaskColor(String taskType) {
    switch (taskType) {
      case 'Bón phân':
        return Colors.brown;
      case 'Tưới nước':
        return Colors.blue;
      case 'Phun thuốc':
        return Colors.purple;
      case 'Tỉa cành':
        return Colors.green;
      case 'Thu hoạch':
        return Colors.orange;
      case 'Xử lý sâu bệnh':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskIcon(String taskType) {
    switch (taskType) {
      case 'Bón phân':
        return Icons.eco;
      case 'Tưới nước':
        return Icons.water_drop;
      case 'Phun thuốc':
        return Icons.sanitizer;
      case 'Tỉa cành':
        return Icons.content_cut;
      case 'Thu hoạch':
        return Icons.shopping_basket;
      case 'Xử lý sâu bệnh':
        return Icons.bug_report;
      default:
        return Icons.event_note;
    }
  }
}
