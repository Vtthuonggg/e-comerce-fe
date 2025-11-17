import 'dart:async';
import 'dart:developer';

import 'package:draggable_fab/draggable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/category_api.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/category/edit_category_page.dart';
import 'package:flutter_app/resources/pages/category/list_category_page.dart';
import 'package:flutter_app/resources/pages/product/edit_product_page.dart';
import 'package:flutter_app/resources/widgets/category_item.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/placeholder_food_image.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListProductPage extends NyStatefulWidget {
  static const path = '/list-product';
  ListProductPage({Key? key}) : super(key: key);

  @override
  NyState<ListProductPage> createState() => _ListProductPageState();
}

class _ListProductPageState extends NyState<ListProductPage> {
  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 1);
  CategoryModel? selectedCate;

  String searchQuery = '';
  int _pageSize = 20;
  int _total = 0;
  List<CategoryModel> lstCate = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCate();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchProducts(pageKey);
    });
  }

  Future<void> _fetchCate() async {
    try {
      var res = await api<CategoryApiService>((request) => request.listCategory(
            '',
            1,
            100,
          ));
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

  _fetchProducts(int pageKey) async {
    try {
      Map<String, dynamic> newItems =
          await api<ProductApiService>((request) => request.listProduct(
                searchQuery,
                pageKey,
                _pageSize,
                categoryId: selectedCate?.id,
              ));
      setState(() {
        _total = newItems['meta']?['total'] ?? 0;
        List<Product> products = [];
        newItems["data"].forEach((item) {
          products.add(Product.fromJson(item));
        });
        final isLastPage = products.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(products);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(products, nextPageKey);
        }
      });
    } catch (error) {
      log(error.toString());
      _pagingController.error = error;
    }
  }

  Widget buildItem(Product product) {
    return Column(
      children: [
        InkWell(
          onTap: () => routeTo(EditProductPage.path, data: {'data': product},
              onPop: (_) {
            _pagingController.refresh();
          }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                PlaceholderFoodImage(),
                const SizedBox(width: 16),
                Expanded(child: _buildProductInfo(product)),
                _buildPopupMenu(product),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: Colors.grey[300]),
        ),
      ],
    );
  }

  Widget _buildProductInfo(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name ?? 'Không có tên',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildPriceInfo(product),
      ],
    );
  }

  Widget _buildPriceInfo(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.baseCost != null && product.baseCost! > 0)
          Text('Giá nhập: ${vnd.format(product.baseCost ?? 0)}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        if (product.retailCost != null)
          Text('Giá bán: ${vnd.format(product.retailCost ?? 0)}',
              style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPopupMenu(Product product) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
      onSelected: (value) {
        if (value == 'edit') {
          routeTo(EditProductPage.path, data: {'data': product}, onPop: (_) {
            _pagingController.refresh();
          });
        } else if (value == 'delete') {
          _showDeleteConfirmationDialog(product);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(IconsaxPlusLinear.edit_2, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Sửa'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(IconsaxPlusLinear.trash, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Xóa'),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa món ăn này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await api<ProductApiService>(
                      (request) => request.deleteProduct(product.id!));
                  CustomToast.showToastSuccess(context,
                      description: 'Xóa món ăn thành công');
                  _pagingController.refresh();
                } catch (error) {
                  log(error.toString());
                  CustomToast.showToastError(context,
                      description: getResponseError(error));
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  _debounceSearch() {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      handleSearch();
    });
  }

  handleSearch() {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title:
            Text('Menu món ăn', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              onPressed: () {
                routeTo(ListCategoryPage.path, onPop: (value) {
                  _fetchCate();
                  setState(() {});
                });
              },
              icon: Icon(IconsaxPlusLinear.category_2))
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            CategoryHeader(
              categories: lstCate,
              selectedId: selectedCate?.id,
              onTap: (cate) {
                selectedCate = cate;
                handleSearch();
                setState(() {});
              },
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
              child: TextField(
                onChanged: (value) {
                  setState(() => searchQuery = value);
                  _debounceSearch();
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm món ăn',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng: $_total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: ThemeColor.get(context).primaryAccent,
                onRefresh: () => Future.sync(() => _pagingController.refresh()),
                child: PagedListView<int, dynamic>(
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<dynamic>(
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
                    itemBuilder: (context, item, index) => buildItem(item),
                    noItemsFoundIndicatorBuilder: (_) =>
                        const Center(child: Text("Không tìm thấy món ăn nào")),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      floatingActionButton: DraggableFab(
        securityBottom: 60,
        child: SpeedDial(
          spacing: 30,
          spaceBetweenChildren: 10,
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: Colors.white,
          foregroundColor: ThemeColor.get(context).primaryAccent,
          children: [
            SpeedDialChild(
              child: const Icon(FontAwesomeIcons.plus),
              backgroundColor: ThemeColor.get(context).primaryAccent,
              foregroundColor: Colors.white,
              label: 'Thêm món ăn',
              onTap: () {
                routeTo(
                  EditProductPage.path,
                  onPop: (value) {
                    _pagingController.refresh();
                  },
                );
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.category),
              backgroundColor: ThemeColor.get(context).primaryAccent,
              foregroundColor: Colors.white,
              label: 'Thêm danh mục',
              onTap: () {
                routeTo(
                  EditCategoryPage.path,
                  onPop: (value) {
                    _pagingController.refresh();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
