import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../search/controller/search_results_controller.dart';

class SearchInputController extends GetxController {
  final textController = TextEditingController();
  final query = ''.obs;

  final _box = GetStorage();
  static const _keyLast = 'last_search';
  static const _keyHistory = 'search_history';

  final RxList<String> history = <String>[].obs;
  final int maxHistory = 10;

  Worker? _typeDebounce;

  @override
  void onInit() {
    super.onInit();

    final last = _box.read<String>(_keyLast) ?? '';
    query.value = last;
    textController.text = last;

    final raw = _box.read<List<dynamic>>(_keyHistory);
    if (raw != null) {
      history.assignAll(raw.map((e) => e.toString()));
    }

    debounce<String>(query, (val) {
      _box.write(_keyLast, val);
    }, time: const Duration(milliseconds: 250));

    _typeDebounce = debounce<String>(query, (val) {
      if (Get.isRegistered<SearchResultsController>()) {
        Get.find<SearchResultsController>().fetchSuggestions(val);
      }
    }, time: const Duration(milliseconds: 120));
  }

  void onSearchChanged(String val) {
    query.value = val;

    if (val.trim().length == 1 && Get.isRegistered<SearchResultsController>()) {
      Get.find<SearchResultsController>().fetchSuggestions(val);
    }
  }

  void submitSearch([String? value]) {
    final q = (value ?? textController.text).trim();
    if (q.isEmpty) return;

    query.value = q;
    textController.text = q;

    _box.write(_keyLast, q);

    final idx = history.indexWhere((e) => e.toLowerCase() == q.toLowerCase());
    if (idx != -1) history.removeAt(idx);
    history.insert(0, q);
    if (history.length > maxHistory) {
      history.removeRange(maxHistory, history.length);
    }
    _box.write(_keyHistory, history);

    if (Get.isRegistered<SearchResultsController>()) {
      Get.find<SearchResultsController>().runSearch(q);
    }
  }

  void selectFromHistory(String term) {
    query.value = term;
    textController.text = term;
    submitSearch(term);
  }

  void removeFromHistory(String term) {
    history.remove(term);
    _box.write(_keyHistory, history);
  }

  void clearHistory() {
    history.clear();
    _box.write(_keyHistory, history);
  }

  void clearInput({bool persist = false}) {
    textController.clear();
    textController.selection = const TextSelection.collapsed(offset: 0);
    query.value = '';
    if (persist) _box.write('last_search', '');
    if (Get.isRegistered<SearchResultsController>()) {
      Get.find<SearchResultsController>().suggestions.value = null;
    }
  }

  @override
  void onClose() {
    _box.write(_keyLast, query.value);
    textController.dispose();
    _typeDebounce?.dispose();
    super.onClose();
  }
}
