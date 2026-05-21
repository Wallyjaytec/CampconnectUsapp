import 'package:get/get.dart';

import '../../../core/services/login_service.dart';
import '../../auth/model/customer_login_model.dart';

class CustomerDashboardController extends GetxController {
  final _login = LoginService();

  final totalOrder = 0.obs;
  final totalPendingOrder = 0.obs;
  final totalSuccessOrder = 0.obs;

  final totalPurchaseAmount = 0.0.obs;
  final lastPurchaseAmount = 0.0.obs;
  final lastPurchaseDate = ''.obs;

  final currentMonth = ''.obs;
  final currentMonthPurchase = 0.0.obs;

  final lastMonth = ''.obs;
  final lastMonthPurchase = 0.0.obs;

  final totalWishlistedProduct = 0.obs;
  final totalSupportTickets = 0.obs;
  final walletBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
    fetchDashboard();
  }

  void loadFromStorage() {
    final dash = _login.getDashboardContent();
    _apply(dash);
  }

  void loadFromModel(CustomerDashboardContent? dash) {
    _apply(dash);
    _login.saveDashboardContent(dash);
  }

  Future<void> fetchDashboard() async {
    try {
      final dash = await _login.fetchDashboardFromApi();
      if (dash != null) {
        loadFromModel(dash);
      }
    } catch (e) {
      // Keep current data on error
    }
  }

  void clear() {
    _apply(null);
  }

  void _apply(CustomerDashboardContent? d) {
    if (d == null) {
      totalOrder.value = 0;
      totalPendingOrder.value = 0;
      totalSuccessOrder.value = 0;

      totalPurchaseAmount.value = 0.0;
      lastPurchaseAmount.value = 0.0;
      lastPurchaseDate.value = '';

      currentMonth.value = '';
      currentMonthPurchase.value = 0.0;

      lastMonth.value = '';
      lastMonthPurchase.value = 0.0;

      totalWishlistedProduct.value = 0;
      totalSupportTickets.value = 0;
      walletBalance.value = 0.0;
      return;
    }

    totalOrder.value = d.totalOrder;
    totalPendingOrder.value = d.totalPendingOrder;
    totalSuccessOrder.value = d.totalSuccessfullOrder;

    totalPurchaseAmount.value = d.totalPurchaseAmount.toDouble();
    lastPurchaseAmount.value = d.lastPurchaseAmount.toDouble();
    lastPurchaseDate.value = d.lastPurchaseDate ?? '';

    currentMonth.value = d.currentMonth;
    currentMonthPurchase.value = d.currentMonthPurchase.toDouble();

    lastMonth.value = d.lastMonth;
    lastMonthPurchase.value = d.lastMonthPurchase.toDouble();

    totalWishlistedProduct.value = d.totalWishlistedProduct;
    totalSupportTickets.value = d.totalSupportTickets;
    walletBalance.value = d.walletBalance.toDouble();
  }
}
