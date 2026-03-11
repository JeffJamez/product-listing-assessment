import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

enum ProductListState { initial, loading, loaded, error, refreshing }

class ProductListProvider extends ChangeNotifier {
  final ProductService? _productService;

  ProductListState _state = ProductListState.initial;
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  String _filterQuery = '';
  bool _sortAscending = true;
  final Map<String, VariantModel> _selectedVariants = {};
  final Set<String> _favoriteIds = {};
  String? _errorMessage;

  ProductListProvider({ProductService? productService})
      : _productService = productService;

  ProductListState get state => _state;

  List<ProductModel> get products => List.unmodifiable(_products);

  List<ProductModel> get filteredProducts =>
      List.unmodifiable(_filteredProducts);

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  String? get errorMessage => _errorMessage;

  ProductService get _service =>
      _productService ?? GetIt.instance<ProductService>();

  Future<void> loadProducts() async {
    final isRefreshing = _state == ProductListState.loaded ||
        _state == ProductListState.refreshing;

    _state =
        isRefreshing ? ProductListState.refreshing : ProductListState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _service.fetchProducts();

      _products = fetched;
      _applyFilterAndSort();

      for (final p in _products) {
        if (p.variants.isNotEmpty && !_selectedVariants.containsKey(p.id)) {
          _selectedVariants[p.id] = p.variants.first;
        }
      }

      _state = ProductListState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ProductListState.error;
    }

    notifyListeners();
  }

  void selectVariant(String productId, VariantModel variant) {
    _selectedVariants[productId] = variant;
    notifyListeners();
  }

  VariantModel? selectedVariantFor(String productId) =>
      _selectedVariants[productId];

  void _applyFilterAndSort() {
    var result = List<ProductModel>.from(_products);

    if (_filterQuery.isNotEmpty) {
      final query = _filterQuery.toLowerCase().trim();
      result =
          result.where((p) => p.title.toLowerCase().contains(query)).toList();
    }

    result.sort((a, b) {
      final priceA = _selectedVariants[a.id]?.price ?? double.infinity;
      final priceB = _selectedVariants[b.id]?.price ?? double.infinity;
      return _sortAscending
          ? priceA.compareTo(priceB)
          : priceB.compareTo(priceA);
    });

    _filteredProducts = result;
  }

  void filterProducts(String query) {
    _filterQuery = query;
    _applyFilterAndSort();
    notifyListeners();
  }

  void sortByPrice({required bool ascending}) {
    _sortAscending = ascending;
    _applyFilterAndSort();
    notifyListeners();
  }

  void toggleFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);
}
