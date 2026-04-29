class CustomerBasicInfoResponse {
  final bool success;
  final CustomerBasicInfo? info;
  final String? message;

  CustomerBasicInfoResponse({
    required this.success,
    required this.info,
    this.message,
  });

  factory CustomerBasicInfoResponse.fromJson(Map<String, dynamic> json) {
    final dataObj = (json['info'] is Map<String, dynamic>)
        ? json['info'] as Map<String, dynamic>
        : (json['customer'] is Map<String, dynamic>)
        ? json['customer'] as Map<String, dynamic>
        : null;

    return CustomerBasicInfoResponse(
      success: json['success'] == true || json['success']?.toString() == 'true',
      info: dataObj != null ? CustomerBasicInfo.fromJson(dataObj) : null,
      message: json['message']?.toString(),
    );
  }
}

class CustomerBasicInfo {
  final String? image;
  final String name;
  final String email;
  final int? id;
  final String? uid;
  final String? phoneWithCode;
  final String? phoneCode;
  final String? phone;
  final String? verifiedAt;

  CustomerBasicInfo({
    required this.image,
    required this.name,
    required this.email,
    required this.id,
    required this.uid,
    required this.phoneWithCode,
    required this.phoneCode,
    required this.phone,
    required this.verifiedAt,
  });

  factory CustomerBasicInfo.fromJson(Map<String, dynamic> json) {
    return CustomerBasicInfo(
      image: json['image']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      uid: json['uid']?.toString(),
      phoneWithCode: json['phone_with_code']?.toString(),
      phoneCode: json['phone_code']?.toString(),
      phone: json['phone']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
    );
  }
}
