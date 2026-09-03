import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  bool isLoading = true;
  String? loadError;
  int unreadCount = 0;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    try {
      final res = await ApiService.get('/v1/notifications');
      if (!mounted) return;
      setState(() {
        notifications = (res is Map ? res['notifications'] : null) as List? ?? [];
        unreadCount = (res is Map ? res['unread_count'] as int? : null) ?? 0;
        isLoading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        notifications = [];
        isLoading = false;
        loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Marks a notification read on the server, then reflects it locally.
  Future<void> _markRead(dynamic notification) async {
    final id = notification is Map ? notification['id'] : null;
    if (id == null || (notification is Map && notification['is_read'] == 1)) return;
    try {
      await ApiService.post('/v1/notifications/$id/read', {});
      if (!mounted) return;
      setState(() {
        notification['is_read'] = 1;
        if (unreadCount > 0) unreadCount--;
      });
    } catch (_) {
      // Non-critical: the badge will correct itself on the next load.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('Notifications & Alerts', style: TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
            : notifications.isEmpty
                ? EmptyStateWidget(
                    icon: loadError != null ? Icons.cloud_off : Icons.notifications_off_outlined,
                    title: loadError != null ? 'Could not load notifications' : 'No Notifications Yet',
                    description: loadError ?? 'Important updates regarding tests, rankings, and daily goals will appear here.',
                    buttonLabel: loadError != null ? 'Try again' : null,
                    onButtonPressed: loadError != null ? _loadNotifications : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppConstants.space12),
                    itemBuilder: (context, i) {
                      final item = notifications[i];
                      final title = item['title'] ?? item['message'] ?? 'Notification';
                      final desc = item['desc'] ?? item['body'] ?? '';
                      final time = item['time'] ?? item['created_at'] ?? 'Today';
                      final color = item['color'] is Color ? item['color'] as Color : AppConstants.accentCyan;

                      final isRead = item['is_read'] == 1 || item['is_read'] == true;

                      return GestureDetector(
                        onTap: () => _markRead(item),
                        child: Opacity(
                          opacity: isRead ? 0.6 : 1.0,
                          child: ExamVerseCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(item['icon'] as IconData? ?? Icons.notifications, color: color, size: 20),
                            ),
                            const SizedBox(width: AppConstants.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(title, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ),
                                      Text(time, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(desc, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12, height: 1.3)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
