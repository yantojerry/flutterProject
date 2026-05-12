import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'stock_badge.dart';

Future<void> showProductDetailsSheet(
  BuildContext context,
  Product product,
) async {
  final String description = product.description.trim().isNotEmpty
      ? product.description.trim()
      : noProductDescription;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext _) {
      return DraggableScrollableSheet(
        initialChildSize: 0.84,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (BuildContext context, ScrollController scrollController) {
          return Material(
            color: context.appSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.appTextSecondary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: <Widget>[
                      _ProductDetailImage(product: product),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'Close details',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      StockBadge(stock: product.stock),
                      const SizedBox(width: 12),
                      Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    productDescriptionLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appTextSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _ProductDetailImage extends StatelessWidget {
  const _ProductDetailImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final String? assetImagePath = resolveProductAssetImagePath(
      product.imageUrl,
    );
    final String networkImageUrl = resolveProductNetworkImageUrl(
      product.imageUrl,
    );

    Widget image;
    if (assetImagePath != null) {
      image = Image.asset(
        assetImagePath,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return _fallback(context, networkImageUrl);
            },
      );
    } else if (networkImageUrl.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: networkImageUrl,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String url) => Container(
          color: context.appInputFill,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (BuildContext context, String url, Object error) {
          return _fallback(context, networkImageUrl);
        },
      );
    } else {
      image = _fallback(context, networkImageUrl);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(height: 240, width: double.infinity, child: image),
    );
  }

  Widget _fallback(BuildContext context, String networkImageUrl) {
    return Container(
      height: 240,
      width: double.infinity,
      color: context.appInputFill,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            networkImageUrl.isEmpty
                ? Icons.image_not_supported_outlined
                : Icons.broken_image_outlined,
            size: 40,
            color: context.appTextSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'Image unavailable',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }
}
