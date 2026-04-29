import 'package:get/get.dart';

import '../../../data/repositories/category_repository.dart';
import '../model/category_model.dart';
import '../model/subcategory_model.dart';

class CategoryController extends GetxController {
  CategoryController(this._repo);
  final CategoryRepository _repo;

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxInt selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      error.value = '';
      final data = await _repo.fetchMegaCategories();

      final withAll = data.map(_injectAllProducts).toList();

      categories.assignAll(withAll);
      if (selectedIndex.value >= categories.length) selectedIndex.value = 0;
    } catch (e) {
      error.value = 'Something went wrong'.tr;
      categories.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(int index) {
    if (index != selectedIndex.value) selectedIndex.value = index;
  }

  CategoryModel _injectAllProducts(CategoryModel cat) {
    final subs = List<SubcategoryModel>.from(cat.subcategories);

    final alreadyHasAll = subs.any((s) => s.isAll);
    if (!alreadyHasAll) {
      subs.insert(
        0,
        const SubcategoryModel(
          id: 0,
          name: 'All Products',
          slug: 'all-products',
          children: [],
        ),
      );
    }

    return CategoryModel(
      id: cat.id,
      name: cat.name,
      slug: cat.slug,
      icon: cat.icon,
      subcategories: subs,
    );
  }
}
