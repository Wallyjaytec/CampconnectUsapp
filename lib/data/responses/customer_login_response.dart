import '../../modules/auth/model/customer_login_model.dart';

class CustomerLoginResponse {
  final bool success;
  final String? accessToken;
  final bool tokenRefresh;
  final String? tokenType;
  final int? expiresIn;
  final CustomerLoginUser? user;
  final CustomerDashboardContent? dashboardContent;
  final List<dynamic>? notifications;
  final String? message;

  CustomerLoginResponse({
    required this.success,
    this.accessToken,
    this.tokenRefresh = false,
    this.tokenType,
    this.expiresIn,
    this.user,
    this.dashboardContent,
    this.notifications,
    this.message,
  });

  factory CustomerLoginResponse.fromJson(Map<String, dynamic> json) {
    return CustomerLoginResponse(
      success: json['success'] == true || json['success']?.toString() == 'true',
      accessToken: json['access_token']?.toString(),
      tokenRefresh:
          json['token_refresh'] == true ||
          json['token_refresh']?.toString() == 'true',
      tokenType: json['token_type']?.toString(),
      expiresIn: _toIntOrNull(json['expires_in']),
      user: (json['user'] is Map<String, dynamic>)
          ? CustomerLoginUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      dashboardContent: (json['dashboard_content'] is Map<String, dynamic>)
          ? CustomerDashboardContent.fromJson(
              json['dashboard_content'] as Map<String, dynamic>,
            )
          : null,
      notifications:
          (json['notifications'] is Map &&
              (json['notifications'] as Map).containsKey('data'))
          ? ((json['notifications'] as Map)['data'] as List<dynamic>?)
          : (json['notifications'] as List<dynamic>?),
      message: json['message']?.toString(),
    );
  }

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
