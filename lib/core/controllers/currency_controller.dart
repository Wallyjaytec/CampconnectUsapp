import '../../core/services/widget_data_service.dart';
import 'package:get/get.dart';

import '../../data/models/site_settings_properties_model.dart';
import '../../data/repositories/site_settings_properties_repository.dart';
import '../services/currency_service.dart';

class CurrencyController extends GetxController {
  final SiteSettingsPropertiesRepository repo;
  final CurrencyService service;
  CurrencyController(this.repo, this.service);

  final currencies = <CurrencyModel>[].obs;
  final Rx<CurrencyModel?> selectedRx = Rx<CurrencyModel?>(null);

  final isLoading = false.obs;
  final error = RxnString();

  CurrencyModel? get selected => selectedRx.value;

  @override
  void onInit() {
    super.onInit();
    fetchCurrencies();
  }

  Future<void> fetchCurrencies({bool force = false}) async {
    isLoading.value = true;
    error.value = null;
    try {
      await service.load(force: force);

      currencies.assignAll(service.currencies);
      selectedRx.value = service.current;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void select(CurrencyModel c) {
    service.setCurrency(c, persist: true);
    selectedRx.value = c;
    update();
    // Update widgets with new currency
    WidgetDataService.updateWidgetData(currencySymbol: c.symbol);
  }

  String format(num amount, {bool applyConversion = true}) {
    return service.format(amount, applyConversion: applyConversion);
  }

  void refreshSelected() {
    selectedRx.value = service.current;
    update();
  }
}
