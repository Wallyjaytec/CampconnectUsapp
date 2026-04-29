import '../../modules/auth/model/customer.dart';

class RegistrationResponse {
  final bool success;
  final Customer? customer;
  final String? message;

  RegistrationResponse({required this.success, this.customer, this.message});

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      success: json['success'] == true || json['success'] == 'true',
      customer: (json['customer'] is Map<String, dynamic>)
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }
}
