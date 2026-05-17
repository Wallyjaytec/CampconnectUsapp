class NotificationItem {
  final String id;
  final String message;
  final String link;
  final String? type;
  final int? param;
  final String time;
  final String? image;
  final String? title;

  NotificationItem({
    required this.id,
    required this.message,
    required this.link,
    required this.time,
    this.type,
    this.param,
    this.image,
    this.title,
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
      title: json['title']?.toString(),
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
