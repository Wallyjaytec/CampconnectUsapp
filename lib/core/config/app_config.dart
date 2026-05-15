class AppConfig {
  AppConfig._();

  //base url
  static const String baseUrl = 'https://campconnectus.store';

  //api endpoint
  static const String verifyResetTokenPath =
    '/api/v1/ecommerce-core/auth/verify-customer-reset-password-token';
static const String resetPasswordPath =
    '/api/v1/ecommerce-core/auth/customer-reset-password';
  static const String sitePropertiesPath =
      '/api/v1/ecommerce-core/site-properties';
  static const String localePath = '/api/v1/locale';
  static const String parentCategoriesPath =
      '/api/v1/ecommerce-core/parent-categories';
  static const String megaCategoriesPath =
      '/api/v1/ecommerce-core/mega-categories';
  static const String productsPath = '/api/v1/ecommerce-core/products';
  static const String categoryProductsPath =
      '/api/v1/ecommerce-core/category-products';
  static const String productDetailsPath =
      '/api/v1/ecommerce-core/product-details';
  static const String searchProductsPath =
      '/api/v1/ecommerce-core/search-products';
  static const String searchSuggestionsPath =
      '/api/v1/ecommerce-core/search-suggestions';
  static const String customerRegistrationPath =
      '/api/v1/ecommerce-core/auth/customer-registration';
  static const String customerLoginPath =
      '/api/v1/ecommerce-core/auth/customer-login';
  static const String customerTokenRefreshPath =
      '/api/v1/ecommerce-core/auth/customer-refresh-auth';
  static const String customerBasicInfoPath =
      '/api/v1/ecommerce-core/customer/customer-basic-info';
  static const String updateCustomerBasicInfoPath =
      '/api/v1/ecommerce-core/customer/update-customer-basic-info';
  static const String productReviewsPath =
      '/api/v1/ecommerce-core/get-product-reviews';
  static const String relatedProductsPath =
      '/api/v1/ecommerce-core/related-products';
  static const String appBannerPath =
      '/api/v1/ecommerce-core/active-app-banner';
  static const String flashDealsActivePath =
      '/api/v1/flash-deal/active-flash-deals';
  static const String flashDealDetailsPath =
      '/api/v1/flash-deal/flash-deal-details';
  static const String flashDealProductsPath =
      '/api/v1/flash-deal/flash-deal-products';
  static const String customerWishlistAddPath =
      '/api/v1/ecommerce-core/customer/store-product-to-wishlist';
  static const String customerWishlistPath =
      '/api/v1/ecommerce-core/customer/get-customer-wishlist-product';
  static const String customerWishlistRemovePath =
      '/api/v1/ecommerce-core/customer/product-remove-from-wishlist';
  static const String singleVariantInfoPath =
      '/api/v1/ecommerce-core/single-variant-info';
  static const String colorVariantImagesPath =
      '/api/v1/ecommerce-core/color-variant-images';
  static const String cartItemsPath =
      '/api/v1/ecommerce-core/customer/cart/cart-items-list';
  static const String cartStoreItemPath =
      '/api/v1/ecommerce-core/customer/cart/store-cart-item';
  static const String cartUpdateItemPath =
      '/api/v1/ecommerce-core/customer/cart/update-cart-item';
  static const String cartRemoveItemPath =
      '/api/v1/ecommerce-core/customer/cart/remove-item';
  static const String cartValidateItemsPath =
      '/api/v1/ecommerce-core/cart/validate-cart-items';
  static const String couponCodePath = '/api/v1/ecommerce-core/apply-coupon';
  static const String getCountriesPath = '/api/v1/ecommerce-core/get-countries';
  static const String getStatesOfCountryPath =
      '/api/v1/ecommerce-core/get-states-of-countries';
  static const String getCitiesOfStatePath =
      '/api/v1/ecommerce-core/get-cities-of-state';
  static const String storeCustomerAddressPath =
      '/api/v1/ecommerce-core/customer/store-customer-address';
  static const String getCustomerAllAddressPath =
      '/api/v1/ecommerce-core/customer/get-customer-all-address';
  static const String updateCustomerAddressPath =
      '/api/v1/ecommerce-core/customer/update-customer-address';
  static const String deleteCustomerAddressPath =
      '/api/v1/ecommerce-core/customer/delete-customer-address';
  static const String customerWalletTransactionPath =
      '/api/wallet/v1/customer-wallet-transaction';
  static const String customerWalletSummaryPath =
      '/api/wallet/v1/customer-wallet-summary';
  static const String walletPaymentMethodsPath =
      '/api/wallet/v1/payment-methods';
  static const String walletOfflineRechargePath =
      '/api/wallet/v1/store-offline-payment';
  static const String walletOnlineRechargeLinkPath =
      '/api/wallet/v1/generate-online-wallet-recharge-link';
  static const String compareItemsDetailsPath =
      '/api/v1/ecommerce-core/compare-items-details';
  static const String collectionDetailsPath =
      '/api/v1/ecommerce-core/collection-details';
  static const String collectionAllProductsPath =
      '/api/v1/ecommerce-core/collection-all-products';
  static const String brandsPath = '/api/v1/ecommerce-core/brands';
  static const String customerOrdersPath =
      '/api/v1/ecommerce-core/customer/orders';
  static const String customerOrderDetailsPath =
      '/api/v1/ecommerce-core/customer/order/details';
  static const String shopProductsSummaryPath =
      '/api/v1/multivendor/shop-products';
  static const String shopDetailsPath = '/api/v1/multivendor/shop-details';
  static const String followShopPath =
      '/api/v1/multivendor/store-shop-follower';
  static const String unfollowShopPath = '/api/v1/multivendor/remove-shop-follower';
  static const String shopAllProductsPath =
      '/api/v1/multivendor/shop-all-products';
  static const String shopAllReviewsPath =
      '/api/v1/multivendor/shop-all-reviews';
  static const String cancelOrderPath =
      '/api/v1/ecommerce-core/customer/cancel-order';
  static const String reviewProductPath =
      '/api/v1/ecommerce-core/customer/review-product';
  static const String refundReasonsPath = '/api/refund/v1/get-refund-reasons';
  static const String submitReturnPath =
      '/api/v1/ecommerce-core/customer/order/return';
  static const String generateOrderPaymentPath =
      '/api/v1/ecommerce-core/generate-order-payment-url';
  static const String randomProductsPath =
      '/api/v1/ecommerce-core/random-products';
  static const String refundRequestsPath =
      '/api/v1/ecommerce-core/customer/return-requests';
  static const String getShippingOptionsPath =
      '/api/v1/ecommerce-core/get-shipping-options';
  static String activePickupPointsPath = '/api/v1/pickup-points/active-list';
  static const String activePaymentMethodsPath =
      '/api/v1/ecommerce-core/active-payment-methods';
  static const String customerForgotPasswordPath =
      '/api/v1/ecommerce-core/auth/customer-forgot-password';
  static const String customerEmailResetLinkPath =
      '/api/v1/ecommerce-core/customer/customer-email-reset-link';
  static const String customerResetEmailPath =
      '/api/v1/ecommerce-core/auth/customer-reset-email';  // ← FIXED: Added /auth/
  static const String storeContactMessagePath = '/api/v1/store/contact/message';
  static const String customerCheckoutOrderPath =
      '/api/v1/ecommerce-core/customer/order/create';
  static const String guestCheckoutPath =
      '/api/v1/ecommerce-core/guest/checkout';
  static String guestOrderDetailsPath =
      '/api/v1/ecommerce-core/guest/order/details';
  static const String unreadNotificationsPath =
      '/api/v1/ecommerce-core/customer/get/unread-notification/list';
  static const String markSingleNotificationReadPath =
      '/api/v1/ecommerce-core/customer/mark-as-read-single-notification';
  static const String markAllNotificationsReadPath =
      '/api/v1/ecommerce-core/customer/mark-as-read-all-notification';
  static const String refundRequestDetailsPath =
      '/api/refund/v1/refund-request-details';
  static const String uploadOrderAttachmentPath =
      '/api/v1/ecommerce-core/upload-attachment-in-order';

  //base url + api endpoint
  static String sitePropertiesUrl() => '$baseUrl$sitePropertiesPath';
  static String localeUrl(String apiCode) =>
      '$baseUrl$localePath/${Uri.encodeComponent(apiCode)}';
  static String parentCategoriesUrl() => '$baseUrl$parentCategoriesPath';
  static String megaCategoriesUrl() => '$baseUrl$megaCategoriesPath';
  static String productsUrl() => '$baseUrl$productsPath';
  static String productDetailsUrl() => '$baseUrl$productDetailsPath';
  static String customerRegistrationUrl() =>
      '$baseUrl$customerRegistrationPath';
  static String customerLoginUrl() => '$baseUrl$customerLoginPath';
  static String customerTokenRefreshUrl() =>
      '$baseUrl$customerTokenRefreshPath';
  static String customerBasicInfoUrl() => '$baseUrl$customerBasicInfoPath';
  static String updateCustomerBasicInfoUrl() =>
      '$baseUrl$updateCustomerBasicInfoPath';
  static String productReviewsUrl() => '$baseUrl$productReviewsPath';
  static String activeAppBannerUrl() => '$baseUrl$appBannerPath';
  static String flashDealsActiveUrl() => '$baseUrl$flashDealsActivePath';
  static String flashDealDetailsUrl() => '$baseUrl$flashDealDetailsPath';
  static String flashDealProductsUrl() => '$baseUrl$flashDealProductsPath';
  static String customerWishlistAddUrl() => '$baseUrl$customerWishlistAddPath';
  static String customerWishlistUrl() => '$baseUrl$customerWishlistPath';
  static String customerWishlistRemoveUrl() =>
      '$baseUrl$customerWishlistRemovePath';
  static String singleVariantInfoUrl() => '$baseUrl$singleVariantInfoPath';
  static String colorVariantImagesUrl() => '$baseUrl$colorVariantImagesPath';
  static String cartItemsUrl() => '$baseUrl$cartItemsPath';
  static String cartStoreItemUrl() => '$baseUrl$cartStoreItemPath';
  static String cartUpdateItemUrl() => '$baseUrl$cartUpdateItemPath';
  static String cartRemoveItemUrl() => '$baseUrl$cartRemoveItemPath';
  static String cartValidateItemsUrl() => '$baseUrl$cartValidateItemsPath';
  static String cartApplyCouponUrl() => '$baseUrl$couponCodePath';
  static String getCountriesUrl() => '$baseUrl$getCountriesPath';
  static String getStatesOfCountryUrl() => '$baseUrl$getStatesOfCountryPath';
  static String getCitiesOfStateUrl() => '$baseUrl$getCitiesOfStatePath';
  static String storeCustomerAddressUrl() =>
      '$baseUrl$storeCustomerAddressPath';
  static String getCustomerAllAddressUrl() =>
      '$baseUrl$getCustomerAllAddressPath';
  static String updateCustomerAddressUrl() =>
      '$baseUrl$updateCustomerAddressPath';
  static String deleteCustomerAddressUrl() =>
      '$baseUrl$deleteCustomerAddressPath';
  static String customerWalletTransactionUrl() =>
      '$baseUrl$customerWalletTransactionPath';
  static String customerWalletSummaryUrl() =>
      '$baseUrl$customerWalletSummaryPath';
  static String walletPaymentMethodsUrl() =>
      '$baseUrl$walletPaymentMethodsPath';
  static String walletOfflineRechargeUrl() =>
      '$baseUrl$walletOfflineRechargePath';
  static String walletOnlineRechargeLinkUrl() =>
      '$baseUrl$walletOnlineRechargeLinkPath';
  static String searchProductsUrl() => '$baseUrl$searchProductsPath';
  static String searchSuggestionsUrl() => '$baseUrl$searchSuggestionsPath';
  static String compareItemsDetailsUrl() => '$baseUrl$compareItemsDetailsPath';
  static String collectionDetailsUrl() => '$baseUrl$collectionDetailsPath';
  static String collectionAllProductsUrl() =>
      '$baseUrl$collectionAllProductsPath';
  static String brandsUrl() => '$baseUrl$brandsPath';
  static String customerOrdersUrl() => '$baseUrl$customerOrdersPath';
  static String customerOrderDetailsUrl() =>
      '$baseUrl$customerOrderDetailsPath';
  static String shopProductsSummaryUrl() => '$baseUrl$shopProductsSummaryPath';
  static String shopDetailsUrl() => '$baseUrl$shopDetailsPath';
  static String followShopUrl() => '$baseUrl$followShopPath';
  static String unfollowShopUrl() => '$baseUrl$unfollowShopPath';
  static String shopAllProductsUrl() => '$baseUrl$shopAllProductsPath';
  static String shopAllReviewsUrl() => '$baseUrl$shopAllReviewsPath';
  static String cancelOrderUrl() => '$baseUrl$cancelOrderPath';
  static String reviewProductUrl() => '$baseUrl$reviewProductPath';
  static String refundReasonsUrl() => '$baseUrl$refundReasonsPath';
  static String submitReturnUrl() => '$baseUrl$submitReturnPath';
  static String generateOrderPaymentUrl() =>
      '$baseUrl$generateOrderPaymentPath';
  static String randomProductsUrl() => '$baseUrl$randomProductsPath';
  static String refundRequestsUrl() => '$baseUrl$refundRequestsPath';
  static String getShippingOptionsUrl() => '$baseUrl$getShippingOptionsPath';
  static String activePickupPointsUrl() => '$baseUrl$activePickupPointsPath';
  static String activePaymentMethodsUrl() =>
      '$baseUrl$activePaymentMethodsPath';
  static String customerForgotPasswordUrl() =>
      '$baseUrl$customerForgotPasswordPath';
  static String verifyResetTokenUrl() => '$baseUrl$verifyResetTokenPath';
static String resetPasswordUrl() => '$baseUrl$resetPasswordPath';
  static String customerEmailResetLinkUrl() =>
      '$baseUrl$customerEmailResetLinkPath';
  static String customerResetEmailUrl() => '$baseUrl$customerResetEmailPath';
  static String storeContactMessageUrl() => '$baseUrl$storeContactMessagePath';
  static String customerCheckoutOrderUrl() =>
      '$baseUrl$customerCheckoutOrderPath';
  static String guestCheckoutUrl() => '$baseUrl$guestCheckoutPath';
  static String guestOrderDetailsUrl() => '$baseUrl$guestOrderDetailsPath';
  static String unreadNotificationsUrl() => '$baseUrl$unreadNotificationsPath';
  static String markSingleNotificationReadUrl() =>
      '$baseUrl$markSingleNotificationReadPath';
  static String markAllNotificationsReadUrl() =>
      '$baseUrl$markAllNotificationsReadPath';
  static String refundRequestDetailsUrl() =>
      '$baseUrl$refundRequestDetailsPath';
  static String uploadOrderAttachmentUrl() =>
      '$baseUrl$uploadOrderAttachmentPath';

  //image path custom url
  static const String kLangCode = 'langCode';
  static const String kCurrencyCode = 'currencyCode';

  static String assetUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }
}
