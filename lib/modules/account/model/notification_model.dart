class NotificationItem {
  final String id;
  final String message;
  final String link;
  final String? type;
  final int? param;
  final String time;
  final String? image;  // Add this line

  NotificationItem({
    required this.id,
    required this.message,
    required this.link,
    required this.time,
    this.type,
    this.param,
    this.image,  // Add this line
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
      image: json['image']?.toString(),  // Add this line
    );
  }
}
