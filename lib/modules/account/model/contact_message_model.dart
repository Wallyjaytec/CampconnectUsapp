class ContactMessageResponse {
  final bool success;
  final String? message;

  ContactMessageResponse({required this.success, this.message});

  factory ContactMessageResponse.fromJson(Map<String, dynamic> json) {
    final success =
        (json['success'] == true) || (json['success']?.toString() == 'true');

    return ContactMessageResponse(
      success: success,
      message: json['message']?.toString(),
    );
  }
}
