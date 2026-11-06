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
                      // The API returns title, message, type, created_at and
                      // action_url. This read 'desc'/'body' for the text and
                      // 'time' for the timestamp, neither of which is ever
                      // sent, so every notification rendered with its body
                      // missing. 'color' and 'icon' were read the same way and
                      // could never arrive over JSON at all; the type decides
                      // them instead, so a payment notice no longer looks
                      // identical to a question approval.
                      final title = (item['title'] ?? '').toString().trim();
                      final message = (item['message'] ?? '').toString().trim();
                      final heading = title.isNotEmpty
                          ? title
                          : (message.isNotEmpty ? message : 'Notification');
                      final desc = title.isNotEmpty ? message : '';
                      final time = _relativeTime(item['created_at']);
                      final color = _colorForType(item['type']);

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
                              child: Icon(_iconForType(item['type']), color: color, size: 20),
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
                                        child: Text(heading, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
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

  /// created_at arrives as a MySQL datetime string. Showing it verbatim put
  /// "2026-10-07 12:34:56" in a 11px slot next to the title.
  static String _relativeTime(dynamic raw) {
    final parsed = DateTime.tryParse((raw ?? '').toString().replaceFirst(' ', 'T'));
    if (parsed == null) return '';
    final diff = DateTime.now().difference(parsed);
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  static Color _colorForType(dynamic type) {
    switch ((type ?? '').toString()) {
      case 'subscription':
        return AppConstants.accentEmerald;
      case 'teacher_application':
        return AppConstants.accentIndigo;
      case 'result':
        return AppConstants.accentBlue;
      default:
        return AppConstants.accentCyan;
    }
  }

  static IconData _iconForType(dynamic type) {
    switch ((type ?? '').toString()) {
      case 'subscription':
        return Icons.workspace_premium_outlined;
      case 'teacher_application':
        return Icons.verified_user_outlined;
      case 'result':
        return Icons.assignment_turned_in_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
