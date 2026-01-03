import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/networking/ingredient_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/ingredient/edit_ingredient_page.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListIngredientPage extends NyStatefulWidget {
  static const path = '/list-ingredient';
  ListIngredientPage({super.key});

  @override
  NyState<ListIngredientPage> createState() => _ListIngredientPageState();
}

class _ListIngredientPageState extends NyState<ListIngredientPage> {
  final PagingController<int, Ingredient> _pagingController =
      PagingController(firstPageKey: 1);

  String searchQuery = '';
  int _pageSize = 20;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchData(pageKey);
    });
  }

  _fetchData(int pageKey) async {
    try {
      Map<String, dynamic> newItems =
          await api<IngredientApiService>((request) => request.listIngredient(
                searchQuery,
                pageKey,
                _pageSize,
              ));
      setState(() {
        List<Ingredient> products = [];
        _total = newItems['meta']?['total'] ?? 0;
        newItems["data"].forEach((item) {
          products.add(Ingredient.fromJson(item));
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

  Widget buildItem(Ingredient item) {
    return Column(
      children: [
        InkWell(
          onTap: () => routeTo(EditIngredientPage.path, data: {'data': item},
              onPop: (_) {
            _pagingController.refresh();
          }),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildItemImage(item),
                const SizedBox(width: 16),
                Expanded(child: _buildItemInfo(item)),
                _buildPopupMenu(item),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ],
    );
  }

  Widget _buildItemImage(Ingredient item) {
    final dynamic img = (item as dynamic).image;
    final bool hasImage = img != null && img.toString().isNotEmpty;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: hasImage ? null : Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasImage
            ? Image.network(
                img.toString(),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderImage(),
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade400,
        size: 32,
      ),
    );
  }

  Widget _buildItemInfo(Ingredient item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name ?? 'Không có tên',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildPriceInfo(item),
        const SizedBox(height: 4),
        _buildChips(item),
      ],
    );
  }

  Widget _buildPriceInfo(Ingredient item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.baseCost != null)
          Text(
            'Giá nhập: ${item.baseCost}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        if (item.retailCost != null)
          Text(
            'Giá bán: ${item.retailCost}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildChips(Ingredient item) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            'Tồn: ${item.inStock ?? 0}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (item.unit != null && item.unit != '')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              item.unit!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPopupMenu(Ingredient item) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey[600],
        size: 20,
      ),
      onSelected: (value) {
        if (value == 'edit') {
          routeTo(EditIngredientPage.path, data: {'data': item}, onPop: (_) {
            _pagingController.refresh();
          });
        } else if (value == 'delete') {
          _showDeleteConfirmationDialog(item);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(
          'Danh sách nguyên liệu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              routeTo(EditIngredientPage.path, onPop: (_) {
                _pagingController.refresh();
              });
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                Future.delayed(Duration(milliseconds: 500), () {
                  if (mounted) _pagingController.refresh();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nguyên liệu',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
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
                Text('Tổng: $_total'),
                SizedBox(width: 8),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              color: ThemeColor.get(context).primaryAccent,
              onRefresh: () => Future.sync(
                () => _pagingController.refresh(),
              ),
              child: PagedListView<int, dynamic>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<dynamic>(
                  firstPageErrorIndicatorBuilder: (context) => Center(
                    child: Text(getResponseError(_pagingController.error)),
                  ),
                  newPageErrorIndicatorBuilder: (context) => Center(
                    child: Text(getResponseError(_pagingController.error)),
                  ),
                  firstPageProgressIndicatorBuilder: (context) =>
                      Center(child: AppLoading()),
                  newPageProgressIndicatorBuilder: (context) =>
                      Center(child: AppLoading()),
                  itemBuilder: (context, item, index) => buildItem(item),
                  noItemsFoundIndicatorBuilder: (_) =>
                      Center(child: const Text("Không tìm thấy sản phẩm nào")),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Ingredient item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa nguyên liệu này không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await api<IngredientApiService>(
                      (request) => request.deleteIngredient(item.id!));
                  CustomToast.showToastSuccess(context,
                      description: 'Xóa nguyên liệu thành công');
                  _pagingController.refresh();
                } catch (error) {
                  log(error.toString());
                  CustomToast.showToastError(context,
                      description: getResponseError(error));
                }
              },
              child: Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
