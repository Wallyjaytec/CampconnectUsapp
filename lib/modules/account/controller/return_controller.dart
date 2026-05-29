import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/services/permission_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/permission_service.dart';
import '../../../data/repositories/my_order_repository.dart';
import '../model/refund_reason_model.dart';

class ReturnController extends GetxController {
  ReturnController({
    OrderRepository? repo,
    required this.orderId,
    required this.packageId,
  }) : _repo = repo ?? OrderRepository();

  final OrderRepository _repo;
  final int orderId;
  final int packageId;

  final RxBool loadingReasons = false.obs;
  final RxList<RefundReason> reasons = <RefundReason>[].obs;

  final Rxn<RefundReason> selectedReason = Rxn<RefundReason>();
  final Rxn<int> selectedReasonId = Rxn<int>();

  final RxString comment = ''.obs;
  final RxList<XFile> images = <XFile>[].obs;
  final RxBool submitting = false.obs;

  final ImagePicker _picker = ImagePicker();

  bool _reasonsRequestedOnce = false;

  RxBool get reasonsLoading => loadingReasons;

  @override
  void onInit() {
    super.onInit();
    ever<int?>(selectedReasonId, (_) => _syncSelectedFromId());
    ever<List<RefundReason>>(reasons, (_) => _syncSelectedFromId());
    loadReasons();
  }

  void ensureReasonsLoaded() {
    if (_reasonsRequestedOnce) return;
    _reasonsRequestedOnce = true;
    if (reasons.isEmpty) loadReasons();
  }

  Future<void> loadReasons() async {
    loadingReasons.value = true;
    try {
      final list = await _repo.fetchRefundReasons();
      reasons.assignAll(list);

      if (selectedReasonId.value == null) {
        selectedReason.value = null;
      } else {
        _syncSelectedFromId();
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        'Something went wrong'.tr,
        backgroundColor: AppColors.primaryColor,
        snackPosition: SnackPosition.TOP,
        colorText: AppColors.whiteColor,
      );
    } finally {
      loadingReasons.value = false;
    }
  }

  void _syncSelectedFromId() {
    final id = selectedReasonId.value;
    if (id == null) {
      selectedReason.value = null;
      return;
    }
    final r = reasons.firstWhereOrNull((e) => e.id == id);
    selectedReason.value = r;
  }

  void setSelectedReasonId(int? id) {
    selectedReasonId.value = id;
  }

  void setSelectedReason(RefundReason? r) {
    selectedReason.value = r;
    selectedReasonId.value = r?.id;
  }

  Future<void> pickFromCamera() async {
    final allowed = await PermissionService.I.canUseCameraOrExplain();
    if (!allowed) return;
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x != null) images.add(x);
  }

  Future<void> pickFromGallery() async {
    final allowed = await PermissionService.I.canUseGalleryOrExplain();
    if (!allowed) return;
    final xs = await _picker.pickMultiImage(imageQuality: 85);
    if (xs.isNotEmpty) images.addAll(xs);
  }

  void removeImageAt(int i) {
    if (i >= 0 && i < images.length) images.removeAt(i);
  }

  void clearImages() => images.clear();

  void setComment(String v) => comment.value = v;

  Future<bool> submit() async {
    if (submitting.value) return false;

    _syncSelectedFromId();

    final reason = selectedReason.value;
    if (reason == null) {
      return false;
    }

    submitting.value = true;
    try {
      final files = <http.MultipartFile>[];
      for (final x in images) {
        files.add(await http.MultipartFile.fromPath('return_images[]', x.path));
      }

      final ok = await _repo.submitReturnRequest(
        packageId: packageId,
        refundReasonId: reason.id,
        refundComment: comment.value.trim(),
        images: files,
      );

      return ok;
    } catch (e) {
      return false;
    } finally {
      submitting.value = false;
    }
  }
}
