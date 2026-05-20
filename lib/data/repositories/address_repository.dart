import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/account/model/address_model.dart';

class AddressRepository {
  AddressRepository(this._api);
  final ApiService _api;

  Future<List<CountryModel>> getCountries() async {
    final res = await _api.getJson(AppConfig.getCountriesUrl());
    final list = (res['data']?['countries'] as List?) ?? const [];
    return list.map((e) => CountryModel.fromJson(e)).toList();
  }

  Future<List<StateModel>> getStates({required int countryId}) async {
    final res = await _api.postJson(
      AppConfig.getStatesOfCountryUrl(),
      body: {'country_id': countryId},
    );
    final list = (res['data']?['states'] as List?) ?? const [];
    return list.map((e) => StateModel.fromJson(e)).toList();
  }

  Future<List<CityModel>> getCities({required int stateId}) async {
    final res = await _api.postJson(
      AppConfig.getCitiesOfStateUrl(),
      body: {'state_id': stateId},
    );
    final list = (res['data']?['cities'] as List?) ?? const [];
    return list.map((e) => CityModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> addCustomerAddress({
    required String name,
    String? phoneCode,
    required String phone,
    required String postalCode,
    required String address,
    required int countryId,
    required int stateId,
    required int cityId,
  }) async {
    final fields = <String, String>{
      'name': name,
      if (phoneCode != null && phoneCode.isNotEmpty) 'phone_code': phoneCode,
      'phone': phone,
      'postal_code': postalCode,
      'address': address,
      'country': countryId.toString(),
      'state': stateId.toString(),
      'city': cityId.toString(),
    };

    final res = await _api.postMultipart(
      AppConfig.storeCustomerAddressUrl(),
      fields: fields,
    );
    return res;
  }

  Future<List<CustomerAddress>> getAllCustomerAddresses() async {
    final res = await _api.getJson(AppConfig.getCustomerAllAddressUrl());
    final list = (res['data'] as List?) ?? const [];
    return list.map((e) => CustomerAddress.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> updateCustomerAddress({
    required int id,
    required String name,
    String? phoneCode,
    required String phone,
    required String postalCode,
    required String address,
    required int status,
    required int defaultShipping,
    required int defaultBilling,
    required int countryId,
    required int stateId,
    required int cityId,
  }) async {
    final res = await _api.postMultipart(
      AppConfig.updateCustomerAddressUrl(),
      fields: {
        'id': id.toString(),
        'name': name,
        if (phoneCode != null && phoneCode.isNotEmpty) 'phone_code': phoneCode,
        'phone': phone,
        'postal_code': postalCode,
        'address': address,
        'status': status.toString(),
        'default_shipping': defaultShipping.toString(),
        'default_billing': defaultBilling.toString(),
        'country': countryId.toString(),
        'state': stateId.toString(),
        'city': cityId.toString(),
      },
    );
    return res;
  }

  // FIXED: Changed from POST to GET
  Future<void> deleteCustomerAddress(int addressId) async {
    await _api.getJson(
      '${AppConfig.deleteCustomerAddressUrl()}?id=$addressId',
    );
  }
}
