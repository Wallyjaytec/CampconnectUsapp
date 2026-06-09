class PickupPoint {
  final int id;
  final String name;
  final String location;
  final String phone;
  final int zoneId;
  final String zoneName;
  final int? sellerId;

  PickupPoint({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.zoneId,
    required this.zoneName,
    this.sellerId,
  });

  factory PickupPoint.fromJson(Map<String, dynamic> j) {
    int i(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return PickupPoint(
      id: i(j['id']),
      name: j['name']?.toString() ?? '',
      location: j['location']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      zoneId: i(j['zone_id'] ?? j['zone']),
      zoneName: j['zone_name']?.toString() ?? '',
      sellerId: j['seller_id'] != null ? i(j['seller_id']) : null,
    );
  }
}

class PickupPointResponse {
  final List<PickupPoint> data;
  final bool success;
  final int status;

  PickupPointResponse({
    required this.data,
    required this.success,
    required this.status,
  });

  factory PickupPointResponse.fromJson(Map<String, dynamic> j) {
    final arr = (j['data'] as List?) ?? const [];
    return PickupPointResponse(
      data: arr.map((e) => PickupPoint.fromJson(e as Map<String, dynamic>)).toList(),
      success: j['success'] == true,
      status: (j['status'] as num?)?.toInt() ?? 0,
    );
  }
}
