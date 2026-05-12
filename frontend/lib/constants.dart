import 'package:flutter/foundation.dart';

const String _androidEmulatorBaseUrl = 'http://10.0.2.2:3000';
const String _localhostBaseUrl = 'http://127.0.0.1:3000';
const String _webBaseUrl = 'http://localhost:3000';
const String _apiBaseUrlOverride = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String get baseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride;
  }

  if (kIsWeb) {
    return _webBaseUrl;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return _androidEmulatorBaseUrl;
    case TargetPlatform.iOS:
      return _webBaseUrl;
    default:
      return _localhostBaseUrl;
  }
}

String get loginEndpoint => '$baseUrl/login';
String get productsEndpoint => '$baseUrl/products';
String get imagesBaseUrl => '$baseUrl/images';

const String appTitle = 'InventoryPro';
const String loginTitle = 'Login';
const String productsTitle = 'Products';
const String addProductTitle = 'Add Product';
const String editProductTitle = 'Edit Product';
const String dashboardTitle = 'Dashboard';
const String profileTitle = 'Profile';
const String inventoryProName = 'InventoryPro';

const String productPlaceholderAsset = 'assets/images/1.jpg';

const String emptyProductsTitle = 'No products yet';
const String emptyProductsSubtitle =
    'Add your first product to start tracking inventory.';
const String emptySearchTitle = 'No matching products';
const String emptySearchSubtitle =
    'Try a different search term or clear the filter.';

const String networkErrorMessage = 'Could not connect to the backend.';
const String genericErrorMessage = 'Something went wrong.';
const String deleteConfirmationTitle = 'Delete product?';
const String deleteConfirmationMessage = 'This action cannot be undone.';
const String deleteButtonText = 'Delete';
const String cancelButtonText = 'Cancel';
const String productAddedMessage = 'Product added!';
const String productUpdatedMessage = 'Product updated!';
const String productDeletedMessage = 'Product deleted!';
const String loginSuccessMessage = 'Welcome back!';
