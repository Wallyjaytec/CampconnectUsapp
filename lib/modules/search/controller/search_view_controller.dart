import 'package:kartly_e_commerce/modules/search/controller/search_input_controller.dart';
import 'package:get/get.dart';

class SearchViewController extends GetxController {
  late final SearchInputController search;
  final tick = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<SearchInputController>()) {
      Get.put(SearchInputController());
    }
    search = Get.find<SearchInputController>();
  }

  @override
  void onReady() {
    super.onReady();
    search.clearInput(persist: true);
    tick.value++;
  }
}
