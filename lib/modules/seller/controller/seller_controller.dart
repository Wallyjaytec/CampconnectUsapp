import 'package:get/get.dart';

class SellerController extends GetxController {
  final name = 'Mother Pray Shop'.obs;
  final logoAsset = 'assets/icons/store.png'.obs;
  final sellerRatingPercent = 81.obs;
  final followers = 2500.obs;
  final isFollowing = false.obs;

  void toggleFollow() => isFollowing.toggle();

  String get followersText {
    final n = followers.value;
    if (n >= 1000000) {
      final v = (n / 1000000);
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}M';
    } else if (n >= 1000) {
      final v = (n / 1000);
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}k';
    }
    return n.toString();
  }
}
