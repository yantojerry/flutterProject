import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'stock_badge.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.subtitle = 'Inventory item',
    this.enabled = true,
  });

  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final String subtitle;
  final bool enabled;

  Color get _accentColor {
    if (product.stock <= 0) {
      return AppColors.error;
    }
    if (product.stock <= 10) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  String get _imageUrl {
    final String imageUrl = product.imageUrl?.trim() ?? '';
    if (imageUrl.isEmpty) {
      return '';
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    return '$baseUrl/images/$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    final Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _accentColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildThumbnail(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₱${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                StockBadge(stock: product.stock),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      onPressed: enabled ? onEdit : null,
                      color: AppColors.primary,
                      tooltip: 'Edit product',
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      onPressed: enabled ? onDelete : null,
                      color: AppColors.error,
                      tooltip: 'Delete product',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: enabled ? onTap : null, child: cardContent),
    );
  }

  Widget _buildThumbnail() {
    if (_imageUrl.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: _imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String url) {
          return Container(
            width: 60,
            height: 60,
            color: AppColors.inputFill,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorWidget: (BuildContext context, String url, Object error) {
          return Container(
            width: 60,
            height: 60,
            color: AppColors.inputFill,
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textSecondary,
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: onPressed == null ? AppColors.textSecondary : color,
            ),
          ),
        ),
      ),
    );
  }
}
