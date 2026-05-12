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
String get registerEndpoint => '$baseUrl/register';
String get productsEndpoint => '$baseUrl/products';
String get imagesBaseUrl => '$baseUrl/images';

String resolveProductNetworkImageUrl(String? imageUrl) {
  final String value = imageUrl?.trim() ?? '';

  if (value.isEmpty) {
    return '';
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final String fileName = value.split('/').last;
  if (fileName.isEmpty) {
    return '';
  }

  return '$baseUrl/images/$fileName';
}

String? resolveProductAssetImagePath(String? imageUrl) {
  final String value = imageUrl?.trim() ?? '';

  if (value.isEmpty) {
    return null;
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return null;
  }

  if (value.startsWith('assets/')) {
    return value;
  }

  final String fileName = value.split('/').last;
  if (fileName.isEmpty) {
    return null;
  }

  return 'assets/images/$fileName';
}

const String appTitle = 'InventoryPro';
const String loginTitle = 'Login';
const String signupTitle = 'Create Account';
const String productsTitle = 'Products';
const String addProductTitle = 'Add Product';
const String editProductTitle = 'Edit Product';
const String productDetailsTitle = 'Product Details';
const String dashboardTitle = 'Dashboard';
const String profileTitle = 'Profile';
const String inventoryProName = 'InventoryPro';
const String betaAccountNotice =
    'Create a beta account directly in InventoryPro.';
const String createAccountButtonText = 'Create account';
const String alreadyHaveAccountText = 'Already have an account?';
const String productDescriptionLabel = 'Description';
const String noProductDescription =
    'No description has been added for this product yet.';

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
