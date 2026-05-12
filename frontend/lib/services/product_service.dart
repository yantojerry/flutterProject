import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  const ProductService();

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse(productsEndpoint));

    if (response.statusCode != 200) {
      throw Exception(_readMessage(response.body, 'Unable to load products.'));
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected product response.');
    }

    return decoded
        .map<Product>(
          (dynamic item) =>
              Product.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<String?> addProduct({
    required String name,
    required double price,
    required int stock,
    required String description,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(productsEndpoint));
    request.fields['name'] = name;
    request.fields['price'] = price.toStringAsFixed(2);
    request.fields['stock'] = stock.toString();
    request.fields['description'] = description;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? 'product.jpg',
          contentType: _guessContentType(imageName),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        _readMessage(response.body, 'Unable to add the product.'),
      );
    }

    return _readImageUrl(response.body);
  }

  Future<String?> updateProduct({
    required Product product,
    required String name,
    required double price,
    required int stock,
    required String description,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$productsEndpoint/${product.id}'),
    );
    request.fields['name'] = name;
    request.fields['price'] = price.toStringAsFixed(2);
    request.fields['stock'] = stock.toString();
    request.fields['description'] = description;
    request.fields['existing_image'] = product.imageUrl ?? '';

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? 'product.jpg',
          contentType: _guessContentType(imageName),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        _readMessage(response.body, 'Unable to update the product.'),
      );
    }

    return _readImageUrl(response.body);
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$productsEndpoint/$id'));

    if (response.statusCode != 200) {
      throw Exception(
        _readMessage(response.body, 'Unable to delete the product.'),
      );
    }
  }
}

String _readMessage(String body, String fallback) {
  try {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> && decoded['message'] != null) {
      return decoded['message'].toString();
    }
  } catch (_) {
    // Fall through to the fallback message.
  }

  return fallback;
}

String? _readImageUrl(String body) {
  try {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final dynamic imageUrl = decoded['image_url'];
      final String? value = imageUrl?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
  } catch (_) {
    // Fall through to null when the response is not JSON.
  }

  return null;
}

MediaType _guessContentType(String? fileName) {
  final extension = fileName == null
      ? ''
      : fileName.split('.').last.toLowerCase();

  switch (extension) {
    case 'png':
      return MediaType('image', 'png');
    case 'gif':
      return MediaType('image', 'gif');
    case 'webp':
      return MediaType('image', 'webp');
    default:
      return MediaType('image', 'jpeg');
  }
}
