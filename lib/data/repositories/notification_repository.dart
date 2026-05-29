import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import '../../modules/account/model/notification_model.dart';

class NotificationRepository {
  NotificationRepository({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  Future<UnreadListResponse> fetchAllNotifications() async {
    final url = AppConfig.allNotificationsUrl();
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

  Future<bool> markSingleAsUnread({required String notificationId}) async {
    final url = AppConfig.markSingleNotificationUnreadUrl();
    final body = {'id': notificationId};
    final json = await _api.postJson(url, body: body);
    return json['success'] == true;
  }

  Future<bool> markAllAsRead() async {
    final url = AppConfig.markAllNotificationsReadUrl();
    final json = await _api.getJson(url);
    final success = json['success'] == true || json['success']?.toString() == 'true';
    return success;
  }

  Future<bool> deleteNotification(String id) async {
    final url = AppConfig.deleteNotificationUrl();
    final json = await _api.postJson(url, body: {'id': id});
    return json['success'] == true;
  }
}
