import 'dart:developer';

import 'package:draggable_fab/draggable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/product/edit_product_page.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  String searchQuery = '';
  int _pageSize = 20;
  int _total = 0;
  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchProducts(pageKey);
    });
  }

  _fetchProducts(int pageKey) async {
    try {
      Map<String, dynamic> newItems =
          await api<ProductApiService>((request) => request.listProduct(
                searchQuery,
                pageKey,
                _pageSize,
                1,
              ));
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: Text('Danh sách sản phẩm',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _pagingController.refresh();
          },
          child: PagedListView<int, dynamic>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<dynamic>(
              firstPageErrorIndicatorBuilder: (context) => Center(
                child: Text(getResponseError(_pagingController.error)),
              ),
              newPageErrorIndicatorBuilder: (context) => Center(
                child: Text(getResponseError(_pagingController.error)),
              ),
              firstPageProgressIndicatorBuilder: (context) => Center(
                child: CircularProgressIndicator(
                  color: ThemeColor.get(context).primaryAccent,
                ),
              ),
              newPageProgressIndicatorBuilder: (context) => Center(
                child: CircularProgressIndicator(
                  color: ThemeColor.get(context).primaryAccent,
                ),
              ),
              itemBuilder: (context, item, index) => buildItem(item),
              noItemsFoundIndicatorBuilder: (_) =>
                  Center(child: const Text("Không tìm thấy sản phẩm nào")),
            ),
          ),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              label: 'Thêm sản phẩm',
              onTap: () {
                routeTo(
                  EditProductPage.path,
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

  Widget buildItem(Product product) {
    return ListTile(
      title: Text(product.name ?? 'No name'),
      subtitle: Text(
          'Giá bán: ${product.retailCost}, Giá gốc: ${product.baseCost}, Tồn kho: ${product.stock}'),
    );
  }
}
