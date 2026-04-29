import '../../product/model/product_model.dart';

class AddressModel {
  final String name;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String zip;
  final bool isDefault;

  const AddressModel({
    required this.name,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.zip,
    this.isDefault = false,
  });

  String get oneLine =>
      '$line1${line2 == null || line2!.isEmpty ? '' : ', $line2'}, $city $zip';
}

class CartLikeItem {
  final ProductModel product;
  final int qty;
  final double unitPrice;
  final Map<String, String> selectedVariants;
  final String? storeName;

  const CartLikeItem({
    required this.product,
    required this.qty,
    required this.unitPrice,
    this.selectedVariants = const {},
    this.storeName,
  });

  double get lineTotal => unitPrice * qty;
}
