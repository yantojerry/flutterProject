import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../theme/app_theme.dart';

class ProductImagePicker extends StatelessWidget {
  const ProductImagePicker({
    super.key,
    required this.onTap,
    this.onRemove,
    this.imageBytes,
    this.imageUrl,
  });

  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final Uint8List? imageBytes;
  final String? imageUrl;

  bool get _hasImage =>
      imageBytes != null || (imageUrl?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _hasImage ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: _hasImage ? 0.08 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _hasImage
                ? _buildImageContent(context)
                : _buildEmptyState(context),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomPaint(
      key: const ValueKey<String>('product_image_picker_empty'),
      painter: _DashedBorderPainter(
        color: AppColors.primary.withValues(alpha: 0.28),
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tap to upload photo',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'PNG, JPG, or WEBP',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final String? assetImagePath = resolveProductAssetImagePath(imageUrl);
    final String networkImageUrl = resolveProductNetworkImageUrl(imageUrl);

    Widget image;
    if (imageBytes != null) {
      image = Image.memory(
        imageBytes!,
        key: const ValueKey<String>('product_image_picker_memory'),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
      );
    } else if (assetImagePath != null) {
      image = Image.asset(
        assetImagePath,
        key: const ValueKey<String>('product_image_picker_asset'),
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          if (networkImageUrl.isEmpty) {
            return _buildNetworkFallback(context);
          }

          return CachedNetworkImage(
            key: const ValueKey<String>('product_image_picker_network_fallback'),
            imageUrl: networkImageUrl,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            placeholder: (BuildContext context, String url) => Container(
              color: AppColors.inputFill,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (BuildContext context, String url, Object error) =>
                _buildNetworkFallback(context),
          );
        },
      );
    } else if (networkImageUrl.isNotEmpty) {
      image = CachedNetworkImage(
        key: const ValueKey<String>('product_image_picker_network'),
        imageUrl: networkImageUrl,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String url) => Container(
          color: AppColors.inputFill,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (BuildContext context, String url, Object error) =>
            _buildNetworkFallback(context),
      );
    } else {
      image = _buildNetworkFallback(context);
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        image,
        if (imageBytes != null && onRemove != null)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.42),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                tooltip: 'Remove image',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkFallback(BuildContext context) {
    return Container(
      key: const ValueKey<String>('product_image_picker_fallback'),
      color: AppColors.inputFill,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 30,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Preview unavailable',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;
  static const double _radius = 16;
  static const double _strokeWidth = 1.4;
  static const double _dashLength = 8;
  static const double _gapLength = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(_radius),
        ),
      );

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = math.min(distance + _dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
