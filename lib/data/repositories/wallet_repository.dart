import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/account/model/wallet_payment_methods_model.dart';
import '../../modules/account/model/wallet_transaction_model.dart';

class WalletRepository {
  final ApiService _api;

  WalletRepository({required ApiService api}) : _api = api;

  Future<WalletTransactionPage> fetchTransactions({
    required int page,
    required int perPage,
    String? entryType,
    String? rechargeType,
    String? dateFrom,
    String? dateTo,
  }) async {
    final body = <String, dynamic>{
      'page': page,
      'perPage': perPage,
    };
    
    var url = AppConfig.customerWalletTransactionUrl();
    final params = <String>[];
    if (entryType != null && entryType.isNotEmpty) params.add('entry_type=$entryType');
    if (rechargeType != null && rechargeType.isNotEmpty) params.add('recharge_type=$rechargeType');
    if (dateFrom != null && dateFrom.isNotEmpty) params.add('date_from=$dateFrom');
    if (dateTo != null && dateTo.isNotEmpty) params.add('date_to=$dateTo');
    if (params.isNotEmpty) url = '$url?${params.join('&')}';

    final res = await _api.postJson(url, body: body);
    return WalletTransactionPage.fromJson(res);
  }

  Future<WalletSummary> fetchWalletSummary() async {
    final res = await _api.postJson(
      AppConfig.customerWalletSummaryUrl(),
      body: const {},
    );
    final summaryMap = (res['summary'] as Map<String, dynamic>? ?? {});
    return WalletSummary.fromJson(summaryMap);
  }

  Future<WalletPaymentMethods> fetchPaymentMethods() async {
    final res = await _api.getJson(AppConfig.walletPaymentMethodsUrl());
    return WalletPaymentMethods.fromJson(res);
  }

  Future<Map<String, dynamic>> submitOfflineRecharge({
    required int rechargeType,
    required String rechargeAmount,
    required String transactionId,
    required int paymentMethodId,
    required int currencyId,
    File? transactionImageFile,
  }) async {
    final fields = <String, String>{
      'recharge_type': rechargeType.toString(),
      'recharge_amount': rechargeAmount,
      'transaction_id': transactionId,
      'payment_method': paymentMethodId.toString(),
      'currency': currencyId.toString(),
    };
    final files = <http.MultipartFile>[];
    if (transactionImageFile != null && await transactionImageFile.exists()) {
      final mp = await http.MultipartFile.fromPath('transaction_image', transactionImageFile.path);
      files.add(mp);
    }
    try {
      final res = await _api.postMultipart(AppConfig.walletOfflineRechargeUrl(), fields: fields, files: files);
      return res;
    } on ApiHttpException catch (e) {
      try {
        final decoded = json.decode(e.body);
        if (decoded is Map<String, dynamic> && (decoded.containsKey('errors') || decoded.containsKey('message'))) {
          throw ApiValidationError.fromJson(decoded);
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<String> generateOnlineRechargeLink({
    required int rechargeType,
    required String rechargeAmount,
    required int currencyId,
    required int paymentMethodId,
  }) async {
    final fields = <String, String>{
      'recharge_type': rechargeType.toString(),
      'recharge_amount': rechargeAmount,
      'currency': currencyId.toString(),
      'payment_method': paymentMethodId.toString(),
      'origin': 'app',
    };
    try {
      final res = await _api.postMultipart(AppConfig.walletOnlineRechargeLinkUrl(), fields: fields, files: const []);
      final ok = res['success'] == true || (res['success']?.toString().toLowerCase() == 'true');
      final url = res['url']?.toString();
      if (!ok || url == null || url.isEmpty) {
        throw ApiHttpException(method: 'POST', url: AppConfig.walletOnlineRechargeLinkUrl(), statusCode: 200, body: 'Missing url in response');
      }
      return url;
    } on ApiHttpException catch (e) {
      try {
        final decoded = json.decode(e.body);
        if (decoded is Map<String, dynamic> && (decoded.containsKey('errors') || decoded.containsKey('message'))) {
          throw ApiValidationError.fromJson(decoded);
        }
      } catch (_) {}
      rethrow;
    }
  }
}
