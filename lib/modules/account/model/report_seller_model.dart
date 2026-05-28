import 'package:get/get.dart';

class ReportSellerModel {
  final int id;
  final String shopName;
  final String reason;
  final int status;
  final String createdAt;
  final String? feedback;

  ReportSellerModel({
    required this.id,
    required this.shopName,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.feedback,
  });

  factory ReportSellerModel.fromJson(Map<String, dynamic> json) {
    return ReportSellerModel(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      shopName: json['shop_name']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status'] is String ? int.tryParse(json['status']) ?? 0 : (json['status'] ?? 0),
      createdAt: json['created_at']?.toString() ?? '',
      feedback: json['feedback']?.toString(),
    );
  }

  String get statusText {
    switch (status) {
      case 0:
        return 'Pending'.tr;
      case 1:
        return 'Reviewed'.tr;
      case 2:
        return 'Resolved'.tr;
      default:
        return 'Unknown'.tr;
    }
  }

  String get hardcodedFeedback {
    switch (status) {
      case 0:
        return 'Report has been sent and waiting for review'.tr;
      case 1:
        return 'Your report has been reviewed and waiting to be resolved'.tr;
      default:
        return '';
    }
  }
}
