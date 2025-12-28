import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/networking/category_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/resources/pages/order/edit_order_page.dart';
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
  final controller = Controller();
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
  List<Product> _selectedItems = [];
  final GlobalKey _buttonKey = GlobalKey();
  int _pageSize = 20;
  String searchQuery = '';
  Timer? _debounce;
  String get roomName => widget.data()?['room_name'];
  String get areaName => widget.data()?['area_name'];
  int get roomId => widget.data()?['room_id'];

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
      final index = _selectedItems.indexWhere((p) => p.id == product.id);

      if (index != -1) {
        // Product đã có trong list
        _selectedItems[index].quantity += delta;
        if (_selectedItems[index].quantity <= 0) {
          _selectedItems.removeAt(index);
        }
      } else if (delta > 0) {
        // Product chưa có, thêm mới
        product.quantity = delta;
        _selectedItems.add(product);
      }
    });
  }

  int _getProductQuantity(int? productId) {
    final product = _selectedItems.firstWhere(
      (p) => p.id == productId,
      orElse: () => Product(),
    );
    return product.id != null ? product.quantity.toInt() : 0;
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
    int totalSelected = _selectedItems.fold<int>(
        0, (sum, product) => sum + product.quantity.toInt());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ThemeColor.get(context).primaryAccent,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${areaName} - ${roomName}',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            CategoryHeader(
              categories: lstCate,
              selectedId: selectedCate?.id,
              onTap: (category) {
                setState(() => selectedCate = category);
                _pagingController.refresh();
              },
            ),
            Expanded(
              child: RefreshIndicator(
                color: ThemeColor.get(context).primaryAccent,
                onRefresh: () => Future.sync(() => _pagingController.refresh()),
                child: PagedListView<int, Product>.separated(
                  pagingController: _pagingController,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Divider(height: 1, color: Colors.grey[300]),
                  ),
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
                    noItemsFoundIndicatorBuilder: (_) => const Center(
                        child: Text("Không tìm thấy sản phẩm nào")),
                    itemBuilder: (context, product, index) {
                      final quantity = _getProductQuantity(product.id);
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
      ),
    );
  }

  Widget _buildBottomActions(int totalSelected) {
    if (totalSelected == 0) {
      return SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 10),
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
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedItems.clear();
                });
              },
              style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black),
              child: Text(
                'Chọn lại',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            key: _buttonKey,
            onPressed: totalSelected > 0
                ? () {
                    routeTo(EditOrderPage.path, data: {
                      'selected_products': _selectedItems,
                      'room_name': roomName,
                      'area_name': areaName,
                      'room_id': roomId,
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: ThemeColor.get(context).primaryAccent,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Row(
              children: [
                Text(
                  'Thêm vào đơn',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(width: 5),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 60,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(Colors.black.withOpacity(0.2),
                        ThemeColor.get(context).primaryAccent),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    roundQuantity(totalSelected),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
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
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isSelected) {
          return;
        }
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
