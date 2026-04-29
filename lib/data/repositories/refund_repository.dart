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
  }) async {
    final url = AppConfig.refundRequestsUrl();

    final res = await _api.postJson(
      url,
      body: {'page': page, 'perPage': perPage},
    );
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
