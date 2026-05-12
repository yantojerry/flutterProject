import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_badge.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onSeeAllProducts});

  final VoidCallback onSeeAllProducts;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = const ProductService();

  List<Product> _products = <Product>[];
  bool _isLoading = true;
  String _errorMessage = '';

  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final List<Product> products = await _productService.fetchProducts();
      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
        _errorMessage = '';
      });
      _entryController.forward(from: 0);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String message = _errorMessageFor(error);
      setState(() {
        _errorMessage = message;
      });

      if (_products.isEmpty) {
        _showSnackBar(message);
      }
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.textPrimary, content: Text(message)),
    );
  }

  String _errorMessageFor(Object error) {
    final String message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return genericErrorMessage;
  }

  List<Product> get _topStockProducts {
    final List<Product> sorted = List<Product>.from(_products)
      ..sort((Product a, Product b) => b.stock.compareTo(a.stock));
    return sorted.take(5).toList(growable: false);
  }

  List<Product> get _recentProducts {
    if (_products.length <= 5) {
      return List<Product>.from(_products);
    }

    return _products.take(5).toList(growable: false);
  }

  int get _lowStockCount =>
      _products
          .where((Product product) => product.stock > 0 && product.stock <= 10)
          .length;

  double get _totalValue => _products.fold<double>(
    0,
    (double total, Product product) => total + (product.price * product.stock),
  );

  String _formatCurrency(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String integerPart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );
    return '$integerPart.${parts.last}';
  }

  Color _stockColor(int stock) {
    if (stock <= 0) {
      return AppColors.error;
    }
    if (stock <= 10) {
      return AppColors.error;
    }
    return AppColors.primary;
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _products.isEmpty) {
      return _DashboardErrorState(
        message: _errorMessage,
        onRetry: () => _loadProducts(showLoading: true),
      );
    }

    final List<Product> topStockProducts = _topStockProducts;
    final List<Product> recentProducts = _recentProducts;

    return RefreshIndicator(
      onRefresh: () => _loadProducts(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          _buildSummarySection(),
          const SizedBox(height: 20),
          _sectionHeader(
            context,
            title: 'Stock Overview',
            subtitle: 'Top 5 products by quantity',
          ),
          const SizedBox(height: 12),
          _buildChartCard(context, topStockProducts),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Recently Added',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: widget.onSeeAllProducts,
                child: const Text('See all →'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentProducts.isEmpty)
            _recentEmptyState(context)
          else
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recentProducts.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int index) {
                  final Product product = recentProducts[index];
                  return _RecentProductCard(
                    product: product,
                    animation: CurvedAnimation(
                      parent: _entryController,
                      curve: Interval(0.1 * index, 0.75, curve: Curves.easeOut),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final List<Widget> cards = <Widget>[
      _AnimatedSummaryCard(
        animation: CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
        ),
        child: SummaryCard(
          title: 'Total Products',
          value: _products.length.toString(),
          icon: Icons.inventory_2,
          color: AppColors.primary,
        ),
      ),
      _AnimatedSummaryCard(
        animation: CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.08, 0.53, curve: Curves.easeOut),
        ),
        child: SummaryCard(
          title: 'Low Stock Items',
          value: _lowStockCount.toString(),
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
        ),
      ),
      _AnimatedSummaryCard(
        animation: CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.16, 0.61, curve: Curves.easeOut),
        ),
        child: SummaryCard(
          title: 'Total Value (₱)',
          value: _formatCurrency(_totalValue),
          icon: Icons.payments_rounded,
          color: AppColors.success,
        ),
      ),
    ];

    return Row(
      children: <Widget>[
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
        const SizedBox(width: 10),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context, List<Product> products) {
    if (products.isEmpty) {
      return Card(
        child: Container(
          height: 240,
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
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
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No chart data yet',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Add products to see stock trends here.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final double maxStock = products.fold<double>(
      0,
      (double maxValue, Product product) =>
          product.stock > maxValue ? product.stock.toDouble() : maxValue,
    );
    final double maxY = maxStock <= 0 ? 10 : maxStock + 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  tooltipRoundedRadius: 12,
                  getTooltipItem:
                      (
                        BarChartGroupData group,
                        int groupIndex,
                        BarChartRodData rod,
                        int rodIndex,
                      ) {
                        final Product product = products[groupIndex];
                        return BarTooltipItem(
                          '${product.name}\n${product.stock} units',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: maxY <= 15 ? 5 : 10,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final int index = value.toInt();
                      if (index < 0 || index >= products.length) {
                        return const SizedBox.shrink();
                      }

                      final String label = _compactLabel(products[index].name);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: 52,
                          child: Text(
                            label,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY <= 15 ? 5 : 10,
                getDrawingHorizontalLine: (double value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: products
                  .asMap()
                  .entries
                  .map((MapEntry<int, Product> entry) {
                    final int index = entry.key;
                    final Product product = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: product.stock.toDouble(),
                          color: _stockColor(product.stock),
                          borderRadius: BorderRadius.circular(10),
                          width: 18,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  })
                  .toList(growable: false),
              groupsSpace: 18,
            ),
            swapAnimationDuration: const Duration(milliseconds: 700),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  Widget _recentEmptyState(BuildContext context) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
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
                Icons.inventory_2_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              emptyProductsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              emptyProductsSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: widget.onSeeAllProducts,
              child: const Text('Go to Products'),
            ),
          ],
        ),
      ),
    );
  }

  String _compactLabel(String value) {
    if (value.length <= 8) {
      return value;
    }
    return '${value.substring(0, 8)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 88,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              dashboardTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Good morning 👋',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _loadProducts(showLoading: false),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh dashboard',
          ),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(context)),
    );
  }
}

class _AnimatedSummaryCard extends StatelessWidget {
  const _AnimatedSummaryCard({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _RecentProductCard extends StatelessWidget {
  const _RecentProductCard({required this.product, required this.animation});

  final Product product;
  final Animation<double> animation;

  String? get _assetImagePath {
    return resolveProductAssetImagePath(product.imageUrl);
  }

  String get _networkImageUrl {
    return resolveProductNetworkImageUrl(product.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(animation),
        child: SizedBox(
          width: 172,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _assetImagePath != null
                        ? Image.asset(
                            _assetImagePath!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  if (_networkImageUrl.isEmpty) {
                                    return Container(
                                      height: 100,
                                      color: AppColors.inputFill,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  }

                                  return CachedNetworkImage(
                                    imageUrl: _networkImageUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (
                                          BuildContext context,
                                          String url,
                                        ) => Container(
                                          height: 100,
                                          color: AppColors.inputFill,
                                          alignment: Alignment.center,
                                          child: const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                    errorWidget:
                                        (
                                          BuildContext context,
                                          String url,
                                          Object error,
                                        ) {
                                          return Container(
                                            height: 100,
                                            color: AppColors.inputFill,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.broken_image_outlined,
                                              color: AppColors.textSecondary,
                                            ),
                                          );
                                        },
                                  );
                                },
                          )
                        : _networkImageUrl.isEmpty
                        ? Container(
                            height: 100,
                            width: double.infinity,
                            color: AppColors.inputFill,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: _networkImageUrl,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (BuildContext context, String url) =>
                                Container(
                                  height: 100,
                                  color: AppColors.inputFill,
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (
                                  BuildContext context,
                                  String url,
                                  Object error,
                                ) {
                                  return Container(
                                    height: 100,
                                    color: AppColors.inputFill,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                },
                          ),
                  ),
                  const SizedBox(height: 10),
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
                    '₱${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  StockBadge(stock: product.stock),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.cloud_off_outlined,
                    color: AppColors.error,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load dashboard',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
