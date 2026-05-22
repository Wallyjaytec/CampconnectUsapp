import 'package:get/get.dart';

import '../../../data/repositories/wallet_repository.dart';
import '../model/wallet_transaction_model.dart';

class WalletController extends GetxController {
  final WalletRepository repo;

  WalletController({required this.repo});

  final RxList<WalletTransaction> items = <WalletTransaction>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final RxInt page = 1.obs;
  final int perPage = 10;

  final Rxn<WalletSummary> summary = Rxn<WalletSummary>();
  final RxBool isSummaryLoading = false.obs;
  final Rxn<WalletPageMeta> meta = Rxn<WalletPageMeta>();

  final RxString filterType = 'all'.obs;
  final RxString filterMethod = 'all'.obs;
  final RxString filterStatus = 'all'.obs;
  final RxString dateFrom = ''.obs;
  final RxString dateTo = ''.obs;

  bool get hasMore {
    final m = meta.value;
    if (m == null) return false;
    return m.currentPage < m.lastPage;
  }

  String? get _entryTypeParam {
    if (filterType.value == 'credit') return '2';
    if (filterType.value == 'debit') return '1';
    return null;
  }

  String? get _rechargeTypeParam {
    if (filterMethod.value == 'online') return '1';
    if (filterMethod.value == 'offline') return '2';
    return null;
  }

  String? get _statusParam {
    if (filterStatus.value == 'pending') return '3';
    if (filterStatus.value == 'declined') return '2';
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    fetchInitial();
  }

  void setFilterType(String type) {
    filterMethod.value = 'all';
    filterStatus.value = 'all';
    dateFrom.value = '';
    dateTo.value = '';
    if (filterType.value == type) {
      filterType.value = 'all';
    } else {
      filterType.value = type;
    }
    refreshList();
  }

  void setFilterMethod(String method) {
    filterType.value = 'all';
    filterStatus.value = 'all';
    dateFrom.value = '';
    dateTo.value = '';
    if (filterMethod.value == method) {
      filterMethod.value = 'all';
    } else {
      filterMethod.value = method;
    }
    refreshList();
  }

  void setFilterStatus(String status) {
    filterType.value = 'all';
    filterMethod.value = 'all';
    dateFrom.value = '';
    dateTo.value = '';
    if (filterStatus.value == status) {
      filterStatus.value = 'all';
    } else {
      filterStatus.value = status;
    }
    refreshList();
  }

  void setDateRange(String from, String to) {
    filterType.value = 'all';
    filterMethod.value = 'all';
    filterStatus.value = 'all';
    if (dateFrom.value == from && dateTo.value == to) {
      dateFrom.value = '';
      dateTo.value = '';
    } else {
      dateFrom.value = from;
      dateTo.value = to;
    }
    refreshList();
  }

  void clearFilters() {
    filterType.value = 'all';
    filterMethod.value = 'all';
    filterStatus.value = 'all';
    dateFrom.value = '';
    dateTo.value = '';
    refreshList();
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
        repo.fetchTransactions(
          page: page.value, perPage: perPage,
          entryType: _entryTypeParam, rechargeType: _rechargeTypeParam,
          status: _statusParam,
          dateFrom: dateFrom.value.isNotEmpty ? dateFrom.value : null,
          dateTo: dateTo.value.isNotEmpty ? dateTo.value : null,
        ),
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
    error.value = '';
    page.value = 1;

    try {
      final results = await Future.wait([
        repo.fetchTransactions(
          page: page.value, perPage: perPage,
          entryType: _entryTypeParam, rechargeType: _rechargeTypeParam,
          status: _statusParam,
          dateFrom: dateFrom.value.isNotEmpty ? dateFrom.value : null,
          dateTo: dateTo.value.isNotEmpty ? dateTo.value : null,
        ),
        repo.fetchWalletSummary(),
      ]);
      final txResp = results[0] as WalletTransactionPage;
      final sumResp = results[1] as WalletSummary;
      meta.value = txResp.meta;
      items.assignAll(txResp.data);
      summary.value = sumResp;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      page.value = page.value + 1;
      final resp = await repo.fetchTransactions(
        page: page.value, perPage: perPage,
        entryType: _entryTypeParam, rechargeType: _rechargeTypeParam,
        status: _statusParam,
        dateFrom: dateFrom.value.isNotEmpty ? dateFrom.value : null,
        dateTo: dateTo.value.isNotEmpty ? dateTo.value : null,
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
