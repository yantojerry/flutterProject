import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      itemCount: 3,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        return const _ShimmerProductCard();
      },
    );
  }
}

class _ShimmerProductCard extends StatelessWidget {
  const _ShimmerProductCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.transparent, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _box(context, 60, 60, borderRadius: 10),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _line(context, widthFactor: 0.72),
                      const SizedBox(height: 10),
                      _line(context, widthFactor: 0.48, height: 10),
                      const SizedBox(height: 18),
                      _line(
                        context,
                        widthFactor: 0.38,
                        height: 18,
                        borderRadius: 999,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    _line(context, width: 90, height: 24, borderRadius: 999),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _box(context, 36, 36, borderRadius: 10),
                        const SizedBox(width: 8),
                        _box(context, 36, 36, borderRadius: 10),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context, {
    double width = double.infinity,
    double? widthFactor,
    double height = 14,
    double borderRadius = 8,
  }) {
    final Widget box = _box(context, width, height, borderRadius: borderRadius);

    if (widthFactor == null) {
      return box;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(widthFactor: widthFactor, child: box),
    );
  }

  Widget _box(
    BuildContext context,
    double width,
    double height, {
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appInputFill,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
