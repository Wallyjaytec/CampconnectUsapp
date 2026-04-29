import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';

class OrderAttachmentResult {
  final bool success;
  final int? fileId;
  final String? fileName;
  final String? path;

  const OrderAttachmentResult({
    required this.success,
    this.fileId,
    this.fileName,
    this.path,
  });
}

class OrderAttachmentRepository {
  final ApiService api;
  OrderAttachmentRepository(this.api);

  Future<OrderAttachmentResult> uploadOrderAttachment(
    File file, {
    int? oldFileId,
  }) async {
    final url = AppConfig.uploadOrderAttachmentUrl();

    final multipart = await http.MultipartFile.fromPath(
      'attachment',
      file.path,
    );

    final fields = <String, String>{};
    if (oldFileId != null) {
      fields['attachment_old'] = oldFileId.toString();
    }

    final res = await api.postMultipart(
      url,
      fields: fields,
      files: [multipart],
    );

    final success =
        res['success'] == true || res['success']?.toString() == 'true';

    int? fileId;
    String? fileName;
    String? path;

    final att = res['attatchment'];
    if (att is Map) {
      fileId = int.tryParse(att['file_id']?.toString() ?? '');
      fileName = att['file_name']?.toString();
      path = att['path']?.toString();
    }

    return OrderAttachmentResult(
      success: success,
      fileId: fileId,
      fileName: fileName,
      path: path,
    );
  }
}
