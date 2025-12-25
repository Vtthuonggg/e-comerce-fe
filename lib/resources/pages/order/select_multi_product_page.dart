import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/category_api.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/widgets/category_item.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class SelectMultiProductPage extends NyStatefulWidget {
  static const path = '/select-multi-product';
  SelectMultiProductPage({super.key});

  @override
  NyState<SelectMultiProductPage> createState() =>
      _SelectMultiProductPageState();
}

class _SelectMultiProductPageState extends NyState<SelectMultiProductPage> {
  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 1);
  List<CategoryModel> lstCate = [];
  CategoryModel? selectedCate;
  Map<int, int> _selectedItems = {};
  final GlobalKey _buttonKey = GlobalKey();
  int _pageSize = 20;
  String searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCate();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchProducts(pageKey);
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchCate() async {
    try {
      var res = await api<CategoryApiService>(
          (request) => request.listCategory('', 1, 100));
      List<CategoryModel> newItems = [];
      res["data"].forEach((item) {
        newItems.add(CategoryModel.fromJson(item));
      });
      lstCate = [];
      var highlightCate = CategoryModel();
      highlightCate.name = 'Nổi bật';
      highlightCate.id = null;
      lstCate.add(highlightCate);
      lstCate.addAll(newItems);
      setState(() {});
    } catch (error) {
      showToastWarning(description: error.toString());
    }
  }

  Future<void> _fetchProducts(int pageKey) async {
    try {
      Map<String, dynamic> response =
          await api<ProductApiService>((request) => request.listProduct(
                searchQuery,
                pageKey,
                _pageSize,
                categoryId: selectedCate?.id,
              ));
      List<Product> products = [];
      response["data"].forEach((item) {
        products.add(Product.fromJson(item));
      });
      final isLastPage = products.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(products);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(products, nextPageKey);
      }
    } catch (error) {
      log(error.toString());
      _pagingController.error = error;
    }
  }

  void _updateQuantity(Product product, int delta) {
    setState(() {
      int currentQty = _selectedItems[product.id] ?? 0;
      int newQty = currentQty + delta;
      if (newQty <= 0) {
        _selectedItems.remove(product.id);
      } else {
        _selectedItems[product.id!] = newQty;
      }
    });
  }

  void _animateToButton(BuildContext context, Offset startPosition) {
    final RenderBox? buttonBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    final buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => TweenAnimationBuilder<Offset>(
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        tween: Tween(begin: startPosition, end: buttonPosition),
        builder: (context, offset, child) {
          return Positioned(
            left: offset.dx,
            top: offset.dy,
            child: Opacity(
              opacity: 1 -
                  (offset.dy - startPosition.dy).abs() /
                      (buttonPosition.dy - startPosition.dy).abs(),
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, color: Colors.grey[500]),
              ),
            ),
          );
        },
        onEnd: () {
          overlayEntry?.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _debounceSearch() {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _pagingController.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalSelected = _selectedItems.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ThemeColor.get(context).primaryAccent,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Phòng 1: Bàn Vip 3',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search dialog
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // TODO: Implement add new product
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Header
          CategoryHeader(
            categories: lstCate,
            selectedId: selectedCate?.id,
            onTap: (category) {
              setState(() => selectedCate = category);
              _pagingController.refresh();
            },
          ),
          Divider(height: 1, color: Colors.grey[300]),
          // Product List
          Expanded(
            child: RefreshIndicator(
              color: ThemeColor.get(context).primaryAccent,
              onRefresh: () => Future.sync(() => _pagingController.refresh()),
              child: PagedListView<int, Product>.separated(
                pagingController: _pagingController,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey[300]),
                builderDelegate: PagedChildBuilderDelegate<Product>(
                  firstPageErrorIndicatorBuilder: (context) => Center(
                      child: Text(getResponseError(_pagingController.error))),
                  newPageErrorIndicatorBuilder: (context) => Center(
                      child: Text(getResponseError(_pagingController.error))),
                  firstPageProgressIndicatorBuilder: (context) => Center(
                      child: CircularProgressIndicator(
                          color: ThemeColor.get(context).primaryAccent)),
                  newPageProgressIndicatorBuilder: (context) => Center(
                      child: CircularProgressIndicator(
                          color: ThemeColor.get(context).primaryAccent)),
                  noItemsFoundIndicatorBuilder: (_) =>
                      const Center(child: Text("Không tìm thấy sản phẩm nào")),
                  itemBuilder: (context, product, index) {
                    final quantity = _selectedItems[product.id] ?? 0;
                    final isSelected = quantity > 0;
                    return _ProductItem(
                      product: product,
                      quantity: quantity,
                      isSelected: isSelected,
                      onTap: (tapContext, position) {
                        _animateToButton(context, position);
                        _updateQuantity(product, 1);
                      },
                      onIncrement: () => _updateQuantity(product, 1),
                      onDecrement: () => _updateQuantity(product, -1),
                    );
                  },
                ),
              ),
            ),
          ),
          // Bottom Actions
          _buildBottomActions(totalSelected),
        ],
      ),
    );
  }

  Widget _buildBottomActions(int totalSelected) {
    if (totalSelected == 0) {
      return SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Đã chọn $totalSelected sản phẩm',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            key: _buttonKey,
            onPressed: totalSelected > 0
                ? () {
                    Navigator.pop(context, _selectedItems);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColor.get(context).primaryAccent,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Xác nhận',
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final Product product;
  final int quantity;
  final bool isSelected;
  final Function(BuildContext, Offset) onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ProductItem({
    required this.product,
    required this.quantity,
    required this.isSelected,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: isSelected
          ? null
          : (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final position = box.localToGlobal(Offset.zero);
              onTap(context, position);
            },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.image, color: Colors.grey[500]),
                      ),
                    )
                  : Icon(Icons.image, color: Colors.grey[500]),
            ),
            SizedBox(width: 12.w),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${product.retailCost?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            // Quantity Controls
            if (isSelected)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    color: Colors.grey[700],
                    onPressed: onDecrement,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$quantity',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    color: ThemeColor.get(context).primaryAccent,
                    onPressed: onIncrement,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
