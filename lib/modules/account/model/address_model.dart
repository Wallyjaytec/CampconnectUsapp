class CountryModel {
  final int id;
  final String name;
  final String code;

  CountryModel({required this.id, required this.name, required this.code});

  factory CountryModel.fromJson(Map<String, dynamic> j) {
    return CountryModel(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      name: j['name']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
    );
  }
}

class StateModel {
  final int id;
  final String name;

  StateModel({required this.id, required this.name});

  factory StateModel.fromJson(Map<String, dynamic> j) {
    return StateModel(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      name: j['name']?.toString() ?? '',
    );
  }
}

class CityModel {
  final int id;
  final String name;

  CityModel({required this.id, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> j) {
    return CityModel(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      name: j['name']?.toString() ?? '',
    );
  }
}

class RefItem {
  final int id;
  final String name;
  const RefItem({required this.id, required this.name});

  factory RefItem.fromJson(Map<String, dynamic> j) => RefItem(
    id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
    name: j['name']?.toString() ?? '',
  );
}

class CustomerAddress {
  final int id;
  final String name;
  final String address;
  final String phoneCode;
  final String phone;
  final String status;
  final RefItem? country;
  final RefItem? state;
  final RefItem? city;
  final String postalCode;
  final int defaultShipping;
  final int defaultBilling;

  const CustomerAddress({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneCode,
    required this.phone,
    required this.status,
    required this.country,
    required this.state,
    required this.city,
    required this.postalCode,
    required this.defaultShipping,
    required this.defaultBilling,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> j) => CustomerAddress(
    id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
    name: j['name']?.toString() ?? '',
    address: (j['address']?.toString() ?? '').replaceAll(r'\r\n', '\n'),
    phoneCode: j['phone_code']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
    status: j['status']?.toString() ?? '',
    country: j['country'] == null ? null : RefItem.fromJson(j['country']),
    state: j['state'] == null ? null : RefItem.fromJson(j['state']),
    city: j['city'] == null ? null : RefItem.fromJson(j['city']),
    postalCode: j['postal_code']?.toString() ?? '',
    defaultShipping: _toInt(j['default_shipping']),
    defaultBilling: _toInt(j['default_billing']),
  );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }
}
