import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final StockStatus status = _statusForStock(stock);
    final Color foregroundColor = status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: foregroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

StockStatus _statusForStock(int stock) {
  if (stock <= 0) {
    return const StockStatus(label: 'Out of Stock', color: AppColors.error);
  }

  if (stock <= 10) {
    return const StockStatus(label: 'Low Stock', color: AppColors.warning);
  }

  return const StockStatus(label: 'In Stock', color: AppColors.success);
}

class StockStatus {
  const StockStatus({required this.label, required this.color});

  final String label;
  final Color color;
}
