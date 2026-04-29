import 'dart:convert';

class RefundReason {
  final int id;
  final String name;

  RefundReason({required this.id, required this.name});

  factory RefundReason.fromMap(Map<String, dynamic> m) => RefundReason(
    id: (m['id'] is String) ? int.tryParse(m['id']) ?? 0 : (m['id'] ?? 0),
    name: m['name']?.toString() ?? '',
  );
}

class RefundReasonsResponse {
  final List<RefundReason> data;
  final bool success;
  final int status;

  RefundReasonsResponse({
    required this.data,
    required this.success,
    required this.status,
  });

  factory RefundReasonsResponse.fromMap(Map<String, dynamic> map) {
    final list = (map['data'] as List? ?? const [])
        .map((e) => RefundReason.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return RefundReasonsResponse(
      data: list,
      success: map['success'] == true,
      status: (map['status'] ?? 0) is String
          ? int.tryParse(map['status']) ?? 0
          : (map['status'] ?? 0),
    );
  }

  static RefundReasonsResponse fromJsonString(String s) =>
      RefundReasonsResponse.fromMap(json.decode(s) as Map<String, dynamic>);
}
