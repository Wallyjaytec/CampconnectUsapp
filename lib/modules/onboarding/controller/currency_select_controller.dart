import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/controllers/currency_controller.dart';
import '../../../data/models/site_settings_properties_model.dart';

class CurrencySelectController extends GetxController {
  final GetStorage _box = GetStorage();
  final RxnString selectedCurrencyCode = RxnString();
  final RxString searchQuery = ''.obs;
  final RxBool isSaving = false.obs;
  
  late final CurrencyController _currencyController;

  List<CurrencyModel> get currencies => _currencyController.currencies;
  bool get isLoading => _currencyController.isLoading.value;

  List<CurrencyModel> get filteredCurrencies {
    if (searchQuery.value.isEmpty) return currencies;
    return currencies.where((c) {
      return c.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
             c.code.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _currencyController = Get.find<CurrencyController>();
  }

  void selectCurrency(String code) {
    selectedCurrencyCode.value = code;
  }

  void saveAndContinue() {
    if (selectedCurrencyCode.value != null) {
      isSaving.value = true;
      
      final currency = currencies.firstWhere((c) => c.code == selectedCurrencyCode.value);
      
      _box.write('selected_currency_code', currency.code);
      _box.write('selected_currency_name', currency.name);
      _box.write('selected_currency_symbol', currency.symbol);
      _box.write('currency_selected', true);
      _box.write('onboarding_done', true);
      
      // APPLY CURRENCY GLOBALLY
      _currencyController.select(currency);
      
      Get.offAllNamed('/bottom_navbar_view');
      
      isSaving.value = false;
    }
  }

  String getCurrencyFlagEmoji(String currencyCode) {
    if (currencyCode.isEmpty) return '🏳️';
    String countryCode = currencyCode.substring(0, 2);
    if (currencyCode == 'EUR') countryCode = 'EU';
    if (currencyCode == 'GBP') countryCode = 'GB';
    
    final first = countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  static bool get isCurrencySelected => GetStorage().read<bool>('currency_selected') ?? false;
  static String? get savedCurrencyCode => GetStorage().read<String>('selected_currency_code');
}
