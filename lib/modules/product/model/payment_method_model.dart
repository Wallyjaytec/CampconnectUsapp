class ActivePaymentMethod {
  final int id;
  final String name;
  final String? logo;
  final String? instruction;

  ActivePaymentMethod({
    required this.id,
    required this.name,
    this.logo,
    this.instruction,
  });

  factory ActivePaymentMethod.fromJson(Map<String, dynamic> j) {
    return ActivePaymentMethod(
      id: (j['id'] is num)
          ? (j['id'] as num).toInt()
          : int.tryParse('${j['id']}') ?? -1,
      name: (j['name'] ?? '').toString(),
      logo: j['logo']?.toString(),
      instruction: (j['instruction'] == null)
          ? null
          : j['instruction'].toString(),
    );
  }
}

class ActivePaymentMethodsResponse {
  final List<ActivePaymentMethod> data;
  final bool success;
  final int status;

  ActivePaymentMethodsResponse({
    required this.data,
    required this.success,
    required this.status,
  });

  factory ActivePaymentMethodsResponse.fromJson(Map<String, dynamic> j) {
    final listRaw = j['data'];
    final list = <ActivePaymentMethod>[];
    if (listRaw is List) {
      for (final e in listRaw) {
        if (e is Map<String, dynamic>) {
          list.add(ActivePaymentMethod.fromJson(e));
        }
      }
    }
    final succ = (j['success'] == true) || (j['success']?.toString() == 'true');
    final st = (j['status'] is num)
        ? (j['status'] as num).toInt()
        : int.tryParse('${j['status']}') ?? 0;
    return ActivePaymentMethodsResponse(data: list, success: succ, status: st);
  }
}
