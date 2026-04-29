import 'package:get/get.dart';

import '../../../data/repositories/wallet_repository.dart';
import '../model/wallet_transaction_model.dart';

class WalletController extends GetxController {
  final WalletRepository repo;

  WalletController({required this.repo});

  final RxList<WalletTransaction> items = <WalletTransaction>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;

  final RxInt page = 1.obs;
  final int perPage = 10;

  final Rxn<WalletSummary> summary = Rxn<WalletSummary>();
  final RxBool isSummaryLoading = false.obs;

  final Rxn<WalletPageMeta> meta = Rxn<WalletPageMeta>();

  bool get hasMore {
    final m = meta.value;
    if (m == null) return false;
    return m.currentPage < m.lastPage;
  }

  int get serialOffset {
    final m = meta.value;
    if (m == null) return (page.value - 1) * perPage;
    return (m.from > 0 ? m.from - 1 : (page.value - 1) * perPage);
  }

  @override
  void onInit() {
    super.onInit();
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    error.value = '';
    isLoading.value = true;
    isSummaryLoading.value = true;
    page.value = 1;
    items.clear();
    summary.value = null;

    try {
      final results = await Future.wait([
        repo.fetchTransactions(page: page.value, perPage: perPage),
        repo.fetchWalletSummary(),
      ]);

      final txResp = results[0] as WalletTransactionPage;
      final sumResp = results[1] as WalletSummary;

      meta.value = txResp.meta;
      items.addAll(txResp.data);
      summary.value = sumResp;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
      isSummaryLoading.value = false;
    }
  }

  Future<void> refreshList() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    error.value = '';
    page.value = 1;

    try {
      final results = await Future.wait([
        repo.fetchTransactions(page: page.value, perPage: perPage),
        repo.fetchWalletSummary(),
      ]);

      final txResp = results[0] as WalletTransactionPage;
      final sumResp = results[1] as WalletSummary;

      meta.value = txResp.meta;
      items.assignAll(txResp.data);
      summary.value = sumResp;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      page.value = page.value + 1;
      final resp = await repo.fetchTransactions(
        page: page.value,
        perPage: perPage,
      );
      meta.value = resp.meta;
      items.addAll(resp.data);
    } catch (e) {
      page.value = page.value - 1;
      error.value = 'Something went wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
