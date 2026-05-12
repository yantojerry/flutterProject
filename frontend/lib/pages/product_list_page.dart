import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../constants.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loader.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';

enum ProductFilter { all, inStock, lowStock, outOfStock }

extension ProductFilterLabel on ProductFilter {
  String get label {
    switch (this) {
      case ProductFilter.all:
        return 'All';
      case ProductFilter.inStock:
        return 'In Stock';
      case ProductFilter.lowStock:
        return 'Low Stock';
      case ProductFilter.outOfStock:
        return 'Out of Stock';
    }
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ProductService _productService = const ProductService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = <Product>[];
  bool _isInitialLoading = true;
  bool _isDeleting = false;
  bool _isSearchExpanded = false;
  bool _showFab = true;
  String _searchQuery = '';
  String _errorMessage = '';
  ProductFilter _activeFilter = ProductFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollDirection direction =
        _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse && _showFab) {
      setState(() {
        _showFab = false;
      });
      return;
    }

    if (direction == ScrollDirection.forward && !_showFab) {
      setState(() {
        _showFab = true;
      });
      return;
    }

    if (_scrollController.position.pixels <= 8 && !_showFab) {
      setState(() {
        _showFab = true;
      });
    }
  }

  Future<void> _loadProducts({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isInitialLoading = true;
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String message = _errorMessageFor(error);
      if (_products.isEmpty) {
        setState(() {
          _errorMessage = message;
        });
      }
      _showSnackBar(message, isError: true);
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _openAddProduct() async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const AddProductPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _loadProducts(showLoading: false);
    }
  }

  Future<void> _openEditProduct(Product product) async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => EditProductPage(product: product),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _loadProducts(showLoading: false);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: deleteConfirmationTitle,
      message: deleteConfirmationMessage,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _productService.deleteProduct(product.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _products.removeWhere((Product item) => item.id == product.id);
      });
      _showSnackBar(productDeletedMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessageFor(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _toggleSearch() {
    final bool nextValue = !_isSearchExpanded;

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearchExpanded = nextValue;
    });

    if (nextValue) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _searchFocusNode.unfocus();
    }
  }

  void _clearSearch() {
    if (!mounted) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _setFilter(ProductFilter filter) {
    if (!mounted) {
      return;
    }

    setState(() {
      _activeFilter = filter;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : null,
        content: Text(message),
      ),
    );
  }

  String _errorMessageFor(Object error) {
    final String message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return genericErrorMessage;
  }

  bool _matchesFilter(Product product) {
    switch (_activeFilter) {
      case ProductFilter.all:
        return true;
      case ProductFilter.inStock:
        return product.stock > 10;
      case ProductFilter.lowStock:
        return product.stock > 0 && product.stock <= 10;
      case ProductFilter.outOfStock:
        return product.stock <= 0;
    }
  }

  List<Product> get _filteredProducts {
    final String query = _searchQuery.trim().toLowerCase();

    return _products
        .where((Product product) {
          final bool matchesQuery =
              query.isEmpty || product.name.toLowerCase().contains(query);
          final bool matchesFilter = _matchesFilter(product);
          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
  }

  Widget _buildSearchArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: _isSearchExpanded ? 72 : 0,
      padding: EdgeInsets.fromLTRB(16, _isSearchExpanded ? 12 : 0, 16, 0),
      child: ClipRect(
        child: Opacity(
          opacity: _isSearchExpanded ? 1 : 0,
          child: CustomTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            labelText: 'Search products',
            hintText: 'Search by name',
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: (String value) {
              if (!mounted) {
                return;
              }

              setState(() {
                _searchQuery = value;
              });
            },
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ProductFilter.values
            .map((ProductFilter filter) {
              final bool selected = _activeFilter == filter;
              return ChoiceChip(
                label: Text(filter.label),
                selected: selected,
                onSelected: (_) => _setFilter(filter),
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? AppColors.primary : Colors.grey.shade200,
                ),
                labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
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
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, size: 34, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    final List<Product> filtered = _filteredProducts;

    if (_errorMessage.isNotEmpty && _products.isEmpty) {
      return _buildErrorScroller();
    }

    if (_products.isEmpty) {
      return _buildScroller(
        child: _buildEmptyState(
          icon: Icons.inventory_2_outlined,
          title: emptyProductsTitle,
          subtitle: emptyProductsSubtitle,
          actionLabel: 'Add your first product',
          onAction: _openAddProduct,
        ),
      );
    }

    if (filtered.isEmpty) {
      final bool hasFilterOrSearch =
          _searchQuery.trim().isNotEmpty || _activeFilter != ProductFilter.all;
      return _buildScroller(
        child: _buildEmptyState(
          icon: hasFilterOrSearch
              ? Icons.search_off_outlined
              : Icons.inventory_2_outlined,
          title: hasFilterOrSearch ? emptySearchTitle : emptyProductsTitle,
          subtitle: hasFilterOrSearch
              ? emptySearchSubtitle
              : emptyProductsSubtitle,
          actionLabel: hasFilterOrSearch
              ? 'Clear filters'
              : 'Add your first product',
          onAction: hasFilterOrSearch
              ? _clearSearchAndFilters
              : _openAddProduct,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(showLoading: false),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: filtered.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Product product = filtered[index];
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 320 + (index * 35)),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset((1 - value) * 24, 0),
                  child: child,
                ),
              );
            },
            child: ProductCard(
              product: product,
              enabled: !_isDeleting,
              onEdit: _isDeleting ? null : () => _openEditProduct(product),
              onDelete: _isDeleting ? null : () => _deleteProduct(product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScroller({required Widget child}) {
    return RefreshIndicator(
      onRefresh: () => _loadProducts(showLoading: false),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.52,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScroller() {
    return _buildScroller(
      child: _buildEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load products',
        subtitle: _errorMessage,
        actionLabel: 'Retry',
        onAction: () => _loadProducts(showLoading: true),
      ),
    );
  }

  void _clearSearchAndFilters() {
    if (!mounted) {
      return;
    }

    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _activeFilter = ProductFilter.all;
    });
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const ShimmerLoader();
    }

    return Column(
      children: <Widget>[
        _buildSearchArea(),
        _buildFilterChips(),
        Expanded(child: _buildProductList(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(productsTitle),
        actions: <Widget>[
          IconButton(
            tooltip: _isSearchExpanded ? 'Close search' : 'Search',
            onPressed: _isDeleting ? null : _toggleSearch,
            icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        offset: _showFab ? Offset.zero : const Offset(0, 1.3),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _showFab ? 1 : 0,
          child: FloatingActionButton.extended(
            onPressed: (_isInitialLoading || _isDeleting)
                ? null
                : _openAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }
}
