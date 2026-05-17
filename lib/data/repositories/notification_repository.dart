import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';

// ============ Notification Model Classes ============
class NotificationItem {
  final String id;
  final String message;
  final String link;
  final String? type;
  final int? param;
  final String time;
  final String? image;

  NotificationItem({
    required this.id,
    required this.message,
    required this.link,
    required this.time,
    this.type,
    this.param,
    this.image,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      type: json['type']?.toString(),
      param: toInt(json['param']),
      time: json['time']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }
}

class UnreadListResponse {
  final bool success;
  final List<NotificationItem> notifications;

  UnreadListResponse({required this.success, required this.notifications});

  factory UnreadListResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true || json['success']?.toString() == 'true';
    final list = (json['notifications']?['data'] as List?) ?? const [];
    final items = list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    return UnreadListResponse(success: success, notifications: items);
  }
}

class SingleMarkResponse {
  final bool success;
  final List<NotificationItem> unreadNotifications;

  SingleMarkResponse({required this.success, required this.unreadNotifications});

  factory SingleMarkResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true || json['success']?.toString() == 'true';
    final list = (json['unread_notification']?['data'] as List?) ?? const [];
    final items = list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    return SingleMarkResponse(success: success, unreadNotifications: items);
  }
}
// ============ End of Model Classes ============

class NotificationRepository {
  NotificationRepository({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  Future<UnreadListResponse> fetchUnreadNotifications() async {
    final url = AppConfig.unreadNotificationsUrl();
    final json = await _api.getJson(url);
    return UnreadListResponse.fromJson(json);
  }

  Future<SingleMarkResponse> markSingleAsRead({
    required String notificationId,
  }) async {
    final url = AppConfig.markSingleNotificationReadUrl();
    final body = {'id': notificationId};
    final json = await _api.postJson(url, body: body);
    return SingleMarkResponse.fromJson(json);
  }

  Future<bool> markAllAsRead() async {
    final url = AppConfig.markAllNotificationsReadUrl();
    final json = await _api.getJson(url);
    final success = json['success'] == true || json['success']?.toString() == 'true';
    return success;
  }
}
