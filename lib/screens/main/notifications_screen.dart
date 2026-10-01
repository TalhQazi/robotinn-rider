import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../models/notification_model.dart';
import '../../providers/rider_auth_provider.dart';
import '../../services/rider_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final list = await RiderApiService.getNotifications();
      if (mounted) setState(() => _notifications = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _markAllRead() async {
    final auth = context.read<RiderAuthProvider>();
    await auth.markAllNotificationsRead();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _markAllRead,
            child: const Text('Mark all read', style: TextStyle(color: AppColors.white, fontSize: 13)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadNotifications(),
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _notifications.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.gray.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No Notifications',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Updates about shifts and orders will be listed here.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notif.read ? AppColors.white : AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(
                            color: notif.read ? AppColors.lightGray : AppColors.primary.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTime(notif.createdAt),
                                    style: const TextStyle(fontSize: 11, color: AppColors.gray),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${d.month}/${d.day}';
    } catch (_) {
      return '';
    }
  }
}
