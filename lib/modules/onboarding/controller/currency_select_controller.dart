import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/controllers/currency_controller.dart';
import '../../../data/models/site_settings_properties_model.dart';

class CurrencySelectController extends GetxController {
  final GetStorage _box = GetStorage();
  final RxnString selectedCurrencyCode = RxnString();
  final RxString searchQuery = ''.obs;
  final RxBool isSaving = false.obs;
  final RxList<CurrencyModel> cachedCurrencies = <CurrencyModel>[].obs;
  
  late final CurrencyController _currencyController;

  List<CurrencyModel> get currencies {
    if (cachedCurrencies.isNotEmpty) {
      return cachedCurrencies;
    }
    return _currencyController.currencies;
  }
  bool get isLoading {
    return _currencyController.isLoading.value && cachedCurrencies.isEmpty;
  }

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
    
    final cached = _box.read<List>('cached_currencies');
    if (cached != null && cached.isNotEmpty) {
      try {
        final currs = cached.map((e) => CurrencyModel.fromJson(e as Map<String, dynamic>)).toList();
        cachedCurrencies.assignAll(currs);
      } catch (_) {}
    }
    
    if (cachedCurrencies.isEmpty && _currencyController.currencies.isEmpty) {
      cachedCurrencies.assignAll([
        CurrencyModel(id: 59, name: 'Argentine Peso', code: 'ARS', symbol: '\$', conversionRate: 1400.96520897, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 15, name: 'Australian Dollar', code: 'AUD', symbol: '\$', conversionRate: 1.39505031, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 39, name: 'Bahraini Dinar', code: 'BHD', symbol: '.د.ب', conversionRate: 0.376, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 3),
        CurrencyModel(id: 51, name: 'Bangladeshi Taka', code: 'BDT', symbol: '৳', conversionRate: 122.73712039, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 21, name: 'Brazilian Real', code: 'BRL', symbol: 'R\$', conversionRate: 5.01284751, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 13, name: 'British Pound', code: 'GBP', symbol: '£', conversionRate: 0.74149308, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 67, name: 'Bulgarian Lev', code: 'BGN', symbol: 'лв', conversionRate: 1.68108162, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 14, name: 'Canadian Dollar', code: 'CAD', symbol: '\$', conversionRate: 1.38085238, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 60, name: 'Chilean Peso', code: 'CLP', symbol: '\$', conversionRate: 896.05236134, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 17, name: 'Chinese Yuan', code: 'CNY', symbol: '¥', conversionRate: 6.78550453, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 61, name: 'Colombian Peso', code: 'COP', symbol: '\$', conversionRate: 3634.37815726, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 66, name: 'Croatian Kuna', code: 'HRK', symbol: 'kn', conversionRate: 6.47607892, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 30, name: 'Czech Koruna', code: 'CZK', symbol: 'Kč', conversionRate: 20.85198947, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 28, name: 'Danish Krone', code: 'DKK', symbol: 'kr', conversionRate: 6.42202519, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 42, name: 'Egyptian Pound', code: 'EGP', symbol: '£', conversionRate: 52.22313579, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 49, name: 'Ethiopian Birr', code: 'ETB', symbol: 'Br', conversionRate: 160.72075758, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 12, name: 'Euro', code: 'EUR', symbol: '€', conversionRate: 0.85952338, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 45, name: 'Ghanaian Cedi', code: 'GHS', symbol: '₵', conversionRate: 11.62153015, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 63, name: 'Hong Kong Dollar', code: 'HKD', symbol: '\$', conversionRate: 7.835035, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 31, name: 'Hungarian Forint', code: 'HUF', symbol: 'Ft', conversionRate: 306.73914559, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 65, name: 'Icelandic Krona', code: 'ISK', symbol: 'kr', conversionRate: 123.44240219, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 20, name: 'Indian Rupee', code: 'INR', symbol: '₹', conversionRate: 95.3803173, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 54, name: 'Indonesian Rupiah', code: 'IDR', symbol: 'Rp', conversionRate: 17786.47128846, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 34, name: 'Israeli Shekel', code: 'ILS', symbol: '₪', conversionRate: 2.88252938, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 16, name: 'Japanese Yen', code: 'JPY', symbol: '¥', conversionRate: 158.94441979, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 41, name: 'Jordanian Dinar', code: 'JOD', symbol: 'د.ا', conversionRate: 0.709, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 3),
        CurrencyModel(id: 44, name: 'Kenyan Shilling', code: 'KES', symbol: 'Sh', conversionRate: 129.48504257, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 38, name: 'Kuwaiti Dinar', code: 'KWD', symbol: 'د.ك', conversionRate: 0.30916984, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 3),
        CurrencyModel(id: 58, name: 'Malaysian Ringgit', code: 'MYR', symbol: 'RM', conversionRate: 3.96487405, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 22, name: 'Mexican Peso', code: 'MXN', symbol: '\$', conversionRate: 17.2808688, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 43, name: 'Moroccan Dirham', code: 'MAD', symbol: 'د.م.', conversionRate: 9.20535082, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 53, name: 'Nepalese Rupee', code: 'NPR', symbol: '₨', conversionRate: 152.68004292, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 64, name: 'New Taiwan Dollar', code: 'TWD', symbol: 'NT\$', conversionRate: 31.49362268, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 24, name: 'New Zealand Dollar', code: 'NZD', symbol: '\$', conversionRate: 1.70817573, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 11, name: 'Nigerian Naira', code: 'NGN', symbol: '₦', conversionRate: 1370.72847448, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 27, name: 'Norwegian Krone', code: 'NOK', symbol: 'kr', conversionRate: 9.251844, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 40, name: 'Omani Rial', code: 'OMR', symbol: '﷼', conversionRate: 0.3849662, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 3),
        CurrencyModel(id: 50, name: 'Pakistani Rupee', code: 'PKR', symbol: '₨', conversionRate: 278.23179213, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 62, name: 'Peruvian Sol', code: 'PEN', symbol: 'S/', conversionRate: 3.40556796, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 55, name: 'Philippine Peso', code: 'PHP', symbol: '₱', conversionRate: 61.60214773, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 29, name: 'Polish Zloty', code: 'PLN', symbol: 'zł', conversionRate: 3.63740862, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 37, name: 'Qatari Rial', code: 'QAR', symbol: '﷼', conversionRate: 3.64, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 68, name: 'Romanian Leu', code: 'RON', symbol: 'lei', conversionRate: 4.50207145, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 33, name: 'Russian Ruble', code: 'RUB', symbol: '₽', conversionRate: 71.60366503, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 48, name: 'Rwandan Franc', code: 'RWF', symbol: 'FRw', conversionRate: 1463.43299761, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 35, name: 'Saudi Riyal', code: 'SAR', symbol: '﷼', conversionRate: 3.75, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 23, name: 'Singapore Dollar', code: 'SGD', symbol: '\$', conversionRate: 1.27720966, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 19, name: 'South African Rand', code: 'ZAR', symbol: 'R', conversionRate: 16.33343341, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 25, name: 'South Korean Won', code: 'KRW', symbol: '₩', conversionRate: 1507.39563547, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 52, name: 'Sri Lankan Rupee', code: 'LKR', symbol: '₨', conversionRate: 327.10492033, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 26, name: 'Swedish Krona', code: 'SEK', symbol: 'kr', conversionRate: 9.30162439, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 18, name: 'Swiss Franc', code: 'CHF', symbol: 'Fr', conversionRate: 0.78313468, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 47, name: 'Tanzanian Shilling', code: 'TZS', symbol: 'TSh', conversionRate: 2618.45748075, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 57, name: 'Thai Baht', code: 'THB', symbol: '฿', conversionRate: 32.59228358, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 32, name: 'Turkish Lira', code: 'TRY', symbol: '₺', conversionRate: 45.90153521, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 36, name: 'UAE Dirham', code: 'AED', symbol: 'د.إ', conversionRate: 3.6725, position: '2', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 46, name: 'Ugandan Shilling', code: 'UGX', symbol: 'USh', conversionRate: 3768.75356116, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
        CurrencyModel(id: 1, name: 'US Dollar', code: 'USD', symbol: '\$', conversionRate: 1, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 2),
        CurrencyModel(id: 56, name: 'Vietnamese Dong', code: 'VND', symbol: '₫', conversionRate: 26348.58565108, position: '1', thousandSeparator: ',', decimalSeparator: '.', numberOfDecimal: 0),
      ]);
    }
    
    if (_currencyController.currencies.isNotEmpty) {
      cachedCurrencies.assignAll(_currencyController.currencies);
      final jsonList = _currencyController.currencies.map((e) => e.toJson()).toList();
      _box.write('cached_currencies', jsonList);
    }
    
    ever(_currencyController.currencies, (List<CurrencyModel> currs) {
      if (currs.isNotEmpty) {
        cachedCurrencies.assignAll(currs);
        final jsonList = currs.map((e) => e.toJson()).toList();
        _box.write('cached_currencies', jsonList);
      }
    });
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
