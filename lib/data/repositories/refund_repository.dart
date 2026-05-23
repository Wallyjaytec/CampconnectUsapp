import '../../../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/account/model/refund_request_details_model.dart';
import '../../modules/account/model/refund_request_model.dart';

class RefundRepository {
  final ApiService _api;

  RefundRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<RefundRequestResponse> fetchRefundRequests({
    required int page,
    required int perPage,
    String? dateFrom,
    String? dateTo,
  }) async {
    final url = AppConfig.refundRequestsUrl();

    final body = <String, dynamic>{'page': page, 'perPage': perPage};
    if (dateFrom != null && dateFrom.isNotEmpty && dateTo != null && dateTo.isNotEmpty) {
      body['date_from'] = '$dateFrom 00:00:00';
      body['date_to'] = '$dateTo 23:59:59';
    }

    final res = await _api.postJson(url, body: body);
    return RefundRequestResponse.fromJson(res);
  }

  Future<RefundRequestDetailsResponse> fetchRefundRequestDetails({
    required int id,
  }) async {
    final url = AppConfig.refundRequestDetailsUrl();
    final res = await _api.postJson(url, body: {'id': id});
    return RefundRequestDetailsResponse.fromJson(res);
  }
}
