import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/app_routes.dart';
import '../../modules/home/model/app_banner_model.dart';

class BannerNav {
  BannerNav._();

  static void _toast(String title, String msg) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  static void _invalid(String msg) => _toast('Invalid link'.tr, msg);

  static bool _looksLikeUrl(String s) {
    final v = s.trim();
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('www.') ||
        v.startsWith('//');
  }

  static Future<void> _openExternal(String url) async {
    final u = Uri.tryParse(url.startsWith('//') ? 'https:$url' : url);
    if (u != null && await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    } else {
      _invalid(url);
    }
  }

  static Future<void> _safeGoNamed(
    String route,
    Map<String, dynamic>? args,
  ) async {
    try {
      await Get.toNamed(route, arguments: args);
    } catch (e) {
      _invalid('${'Route not found'.tr}: $route');
    }
  }

  static Future<void> open(AppBanner b) async {
    final t = b.type.trim().toLowerCase();
    final raw = (b.value ?? '').trim();

    if (raw.isNotEmpty && _looksLikeUrl(raw)) {
      await _openExternal(raw);
      return;
    }

    if (t == 'custom_url' || t == 'customurl' || t == 'custom-url') {
      if (raw.isEmpty) {
        _invalid('URL not found'.tr);
        return;
      }
      await _openExternal(raw);
      return;
    }

    if (t == 'product') {
      if (raw.isEmpty) {
        _invalid('Product link not found'.tr);
        return;
      }
      int? pid;
      String? slug;

      if (RegExp(r'^\d+$').hasMatch(raw)) {
        pid = int.tryParse(raw);
      } else {
        slug = raw;
      }

      if (pid == null && (slug == null || slug.isEmpty)) {
        _invalid('Product link not found'.tr);
        return;
      }

      final args = <String, dynamic>{};
      if (pid != null) {
        args['productId'] = pid;
        args['id'] = pid;
      }
      if (slug != null && slug.isNotEmpty) {
        args['permalink'] = slug;
        args['slug'] = slug;
      }

      await _safeGoNamed(AppRoutes.productDetailsView, args);
      return;
    }

    if (t == 'category') {
      if (raw.isEmpty) {
        _invalid('Category link not found'.tr);
        return;
      }
      final cid = int.tryParse(raw);
      if (cid != null) {
        await _safeGoNamed(AppRoutes.newProductListView, {'categoryId': cid});
      } else {
        await _safeGoNamed(AppRoutes.newProductListView, {'categorySlug': raw});
      }
      return;
    }

    if (t == 'collection') {
      if (raw.isEmpty) {
        _invalid('Collection link not found'.tr);
        return;
      }
      final collectionId = int.tryParse(raw);
      if (collectionId != null) {
        await _safeGoNamed(AppRoutes.collectionView, {
          'collectionId': collectionId,
        });
      } else {
        await _safeGoNamed(AppRoutes.collectionView, {'collectionSlug': raw});
      }
      return;
    }

    if (t == 'flash_deal' || t == 'flashdeal' || t == 'flash-deal') {
      if (raw.isEmpty) {
        _invalid('Flash deal not found'.tr);
        return;
      }
      final fdId = int.tryParse(raw);
      if (fdId != null) {
        await _safeGoNamed(AppRoutes.flashDealsView, {'flashDealId': fdId});
      } else {
        await _safeGoNamed(AppRoutes.flashDealsView, {'flashDealCode': raw});
      }
      return;
    }

    if (t.isNotEmpty) {
      if (raw.isEmpty) {
        _invalid('${'Missing value for type'.tr} "$t"');
        return;
      }
      final id = int.tryParse(raw);
      final route = '/$t';
      final args = id != null
          ? <String, dynamic>{'${t}Id': id}
          : <String, dynamic>{'${t}Slug': raw};

      await _safeGoNamed(route, args);
      return;
    }

    _invalid('Unsupported banner payload'.tr);
  }
}
