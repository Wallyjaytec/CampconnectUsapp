class ForgotPasswordResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? errors;

  ForgotPasswordResponse({required this.success, this.message, this.errors});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is bool) {
      return ForgotPasswordResponse(
        success: json['data'] as bool,
        message: json['message']?.toString(),
        errors: json['errors'] is Map<String, dynamic>
            ? json['errors'] as Map<String, dynamic>
            : null,
      );
    }

    final success =
        (json['success'] == true) || (json['success']?.toString() == 'true');

    return ForgotPasswordResponse(
      success: success,
      message: json['message']?.toString(),
      errors: json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
          : null,
    );
  }

  String? get firstEmailError {
    if (errors == null) return null;
    final emailErrors = errors!['email'];
    if (emailErrors is List && emailErrors.isNotEmpty) {
      return emailErrors.first.toString();
    }
    return null;
  }
}
