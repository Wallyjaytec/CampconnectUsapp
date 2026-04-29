import 'package:get/get.dart';

class DescriptionController extends GetxController {
  final RxBool expanded = false.obs;
  final RxBool needsMore = false.obs;
  void toggle() => expanded.value = !expanded.value;
}
