class Customer {
  final String uid;
  final String name;
  final String email;
  final String phoneCode;
  final String phone;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;

  Customer({
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneCode,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.id,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneCode: json['phone_code']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone_code': phoneCode,
      'phone': phone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'id': id,
    };
  }
}
