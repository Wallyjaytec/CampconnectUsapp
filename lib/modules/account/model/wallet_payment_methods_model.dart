class WalletOnlineMethod {
  final int id;
  final String name;
  final String? logo;

  WalletOnlineMethod({required this.id, required this.name, this.logo});

  factory WalletOnlineMethod.fromJson(Map<String, dynamic> j) {
    return WalletOnlineMethod(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      name: j['name']?.toString() ?? '',
      logo: j['logo']?.toString(),
    );
  }
}

class WalletOfflineMethod {
  final int id;
  final String name;
  final String? logo;
  final String? instructionHtml;
  final String? type;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? routingNumber;

  WalletOfflineMethod({
    required this.id,
    required this.name,
    this.logo,
    this.instructionHtml,
    this.type,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.routingNumber,
  });

  factory WalletOfflineMethod.fromJson(Map<String, dynamic> j) {
    return WalletOfflineMethod(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      name: j['name']?.toString() ?? '',
      logo: j['logo']?.toString(),
      instructionHtml: j['instruction']?.toString(),
      type: j['type']?.toString(),
      bankName: j['bank_name']?.toString(),
      accountName: j['account_name']?.toString(),
      accountNumber: j['account_number']?.toString(),
      routingNumber: j['routing_number']?.toString(),
    );
  }
}

class WalletPaymentMethods {
  final List<WalletOnlineMethod> onlineMethods;
  final List<WalletOfflineMethod> offlineMethods;

  WalletPaymentMethods({
    required this.onlineMethods,
    required this.offlineMethods,
  });

  factory WalletPaymentMethods.fromJson(Map<String, dynamic> j) {
    final online = (j['online_methods'] as List<dynamic>? ?? [])
        .map((e) => WalletOnlineMethod.fromJson(e as Map<String, dynamic>))
        .toList();

    final offlineData = (j['offline_methods']?['data'] as List<dynamic>? ?? []);
    final offline = offlineData
        .map((e) => WalletOfflineMethod.fromJson(e as Map<String, dynamic>))
        .toList();

    return WalletPaymentMethods(onlineMethods: online, offlineMethods: offline);
  }
}

class ApiValidationError {
  final String message;
  final Map<String, List<String>> fieldErrors;

  ApiValidationError({required this.message, required this.fieldErrors});

  factory ApiValidationError.fromJson(Map<String, dynamic> j) {
    final raw = j['errors'] as Map<String, dynamic>? ?? {};
    final fe = <String, List<String>>{};
    raw.forEach((k, v) {
      if (v is List) {
        fe[k] = v.map((e) => e.toString()).toList();
      } else if (v != null) {
        fe[k] = [v.toString()];
      }
    });
    return ApiValidationError(
      message: j['message']?.toString() ?? 'Validation error',
      fieldErrors: fe,
    );
  }

  String? first(String key) {
    final list = fieldErrors[key];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }
}
