import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListProductPage extends NyStatefulWidget {
  static const path = '/list-product';
  ListProductPage({Key? key}) : super(path, key: key);

  @override
  NyState<ListProductPage> createState() => _ListProductPageState();
}

class _ListProductPageState extends NyState<ListProductPage> {
  final PagingController<int, dynamic> _pagingController =
      PagingController(firstPageKey: 1);

  String searchQuery = '';
  int _pageSize = 20;
  int _total = 0;
  @override
  void init() async {
    super.init();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchProducts(pageKey);
    });
  }

  _fetchProducts(int pageKey) async {
    try {
      Map<String, dynamic> newItems =
          await myApi<ProductApiService>((request) => request.listProduct(
                searchQuery,
                pageKey,
                _pageSize,
                1,
              ));
      setState(() {
        _total = newItems['meta'];
        List<Product> products = [];
        newItems["data"].forEach((category) {
          products.add(Product.fromJson(category));
        });
        // _total = newItems['total'];
        final isLastPage = products.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(products);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(products, nextPageKey);
        }
      });
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Danh sách sản phẩm'),
        ),
        body: SafeArea(
          child: PagedListView<int, dynamic>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<dynamic>(
              itemBuilder: (context, item, index) => ListTile(
                title: Text(item.name ?? 'No name'),
                subtitle: Text(
                    'Giá bán: ${item.retailCost}, Giá gốc: ${item.baseCost}, Tồn kho: ${item.stock}'),
              ),
              firstPageErrorIndicatorBuilder: (context) => Center(
                child: Text('Có lỗi xảy ra khi tải dữ liệu.'),
              ),
              noItemsFoundIndicatorBuilder: (context) => Center(
                child: Text('Không có sản phẩm nào.'),
              ),
            ),
          ),
        ));
  }
}
