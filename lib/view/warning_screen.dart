import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/models/notification_model.dart';
import 'package:smart_farm/provider/notification_provider.dart';
import 'package:smart_farm/theme/app_colors.dart';
import 'package:smart_farm/widget/bottom_bar.dart';
import 'package:smart_farm/widget/top_bar.dart';
import 'package:intl/intl.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key});

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
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
            child: TopBar(title: 'Thông báo', isBack: true),
          ),
          Positioned(
            top: 70 * pix,
            left: 0,
            right: 0,
            bottom: 70 * pix,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  if (notificationProvider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      // Header actions
                      _buildHeaderActions(pix, notificationProvider),

                      // Notifications list
                      Expanded(
                        child: notificationProvider.notifications.isEmpty
                            ? _buildEmptyState(pix)
                            : _buildNotificationsList(
                                pix, notificationProvider),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Bottombar(type: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(double pix, NotificationProvider provider) {
    return Container(
      margin: EdgeInsets.all(16 * pix),
      padding: EdgeInsets.all(16 * pix),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * pix),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng thông báo',
                style: TextStyle(
                  fontSize: 14 * pix,
                  color: AppColors.textGrey,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
              SizedBox(height: 4 * pix),
              Row(
                children: [
                  Text(
                    '${provider.notifications.length}',
                    style: TextStyle(
                      fontSize: 24 * pix,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                  SizedBox(width: 8 * pix),
                  if (provider.unreadCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8 * pix, vertical: 4 * pix),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12 * pix),
                      ),
                      child: Text(
                        '${provider.unreadCount} mới',
                        style: TextStyle(
                          fontSize: 12 * pix,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: provider.unreadCount > 0
                ? () async {
                    await provider.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đánh dấu tất cả là đã đọc'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * pix),
              ),
            ),
            child: Text(
              'Đánh dấu đã đọc',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * pix,
                fontFamily: 'BeVietnamPro',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double pix) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80 * pix,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16 * pix),
          Text(
            'Không có thông báo',
            style: TextStyle(
              fontSize: 18 * pix,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'BeVietnamPro',
            ),
          ),
          SizedBox(height: 8 * pix),
          Text(
            'Các cảnh báo từ cảm biến sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14 * pix,
              color: Colors.grey[500],
              fontFamily: 'BeVietnamPro',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(double pix, NotificationProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchNotifications(),
      child: ListView.separated(
        padding: EdgeInsets.all(16 * pix),
        itemCount: provider.notifications.length,
        separatorBuilder: (context, index) => SizedBox(height: 12 * pix),
        itemBuilder: (context, index) {
          final notification = provider.notifications[index];
          return _buildNotificationCard(pix, notification, provider);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    double pix,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return InkWell(
      onTap: () async {
        if (!notification.read) {
          await provider.markAsRead(notification.id);
        }
      },
      borderRadius: BorderRadius.circular(12 * pix),
      child: Container(
        padding: EdgeInsets.all(16 * pix),
        decoration: BoxDecoration(
          color:
              notification.read ? Colors.white : Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12 * pix),
          border: Border.all(
            color: notification.read
                ? Colors.grey.withOpacity(0.2)
                : notification.getTypeColor().withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(10 * pix),
              decoration: BoxDecoration(
                color: notification.getTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10 * pix),
              ),
              child: Icon(
                notification.getTypeIcon(),
                size: 24 * pix,
                color: notification.getTypeColor(),
              ),
            ),
            SizedBox(width: 12 * pix),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.getTypeDisplayName(),
                          style: TextStyle(
                            fontSize: 16 * pix,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8 * pix,
                          height: 8 * pix,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4 * pix),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14 * pix,
                      color: AppColors.textGrey,
                      fontFamily: 'BeVietnamPro',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8 * pix),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12 * pix,
                      color: Colors.grey[500],
                      fontFamily: 'BeVietnamPro',
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
}
