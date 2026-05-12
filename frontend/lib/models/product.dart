class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  final int id;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      price: _asDouble(json['price']),
      stock: _asInt(json['stock']),
      imageUrl: json['image_url']?.toString(),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
