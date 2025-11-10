import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:flutter_app/app/networking/category_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/category/edit_category_page.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListCategoryPage extends NyStatefulWidget {
  static const path = '/list-category';

  ListCategoryPage({super.key});

  @override
  NyState<ListCategoryPage> createState() => _ListCategoryPageState();
}

class _ListCategoryPageState extends NyState<ListCategoryPage> {
  final PagingController<int, CategoryModel> _pagingController =
      PagingController(firstPageKey: 1);
  dynamic _total;
  String searchQuery = '';
  int _pageSize = 20;

  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchData(pageKey);
    });
  }

  _fetchData(int pageKey) async {
    try {
      Map<String, dynamic> newItems =
          await api<CategoryApiService>((request) => request.listCategory(
                searchQuery,
                pageKey,
                _pageSize,
              ));
      setState(() {
        List<CategoryModel> categories = [];
        newItems["data"].forEach((item) {
          categories.add(CategoryModel.fromJson(item));
        });
        final isLastPage = categories.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(categories);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(categories, nextPageKey);
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
          title: Text(
            "Quản lý danh mục",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'create') {
                  routeTo(EditCategoryPage.path, onPop: (value) {
                    _pagingController.refresh();
                  });
                }
              },
              icon: Icon(
                Icons.more_vert,
                size: 30,
                color: Colors.white,
              ),
              offset: Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'create',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: ThemeColor.get(context).primaryAccent,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Tạo mới',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ]),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              SizedBox(height: 10.0),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                    _pagingController.refresh();
                  },
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Tìm kiếm nhóm sản phẩm",
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              Expanded(
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
                    itemBuilder: (context, item, index) =>
                        buildItem(item, context),
                    noItemsFoundIndicatorBuilder: (_) =>
                        Center(child: Text("Không tìm thấy danh mục")),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
      // decoration: BoxDecoration(color: Colors.grey[200]),
      width: double.infinity,
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text.rich(
            TextSpan(
              text: 'Tổng số lượng: ',
              style: TextStyle(fontSize: 14),
              children: <TextSpan>[
                TextSpan(
                  text:
                      '${_total != null ? roundQuantity(_total['total']) : 0}',
                  // text: '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget buildItem(CategoryModel item, BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10.0),
          child: ListTile(
            onTap: () {},
            leading: Icon(
              IconsaxPlusBroken.category_2,
              color: ThemeColor.get(context).primaryAccent,
            ),
            title: Text(
              item.name ?? "",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: (item.description != null)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description ?? "",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : null,
            trailing: PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'delete') {
                  _deleteCategory(item.id);
                }

                if (value == 'edit') {
                  routeTo(EditCategoryPage.path, data: item, onPop: (value) {
                    _pagingController.refresh();
                  });
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Sửa',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Xóa',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(
            color: Colors.grey[300],
          ),
        )
      ],
    );
  }

  void _deleteCategory(int? categoryId) {
    if (categoryId == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận'),
          content: Text('Bạn có chắc chắn muốn xóa danh mục này?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                  side: BorderSide(
                    color: ThemeColor.get(context).primaryAccent,
                  ),
                  backgroundColor: Colors.transparent,
                  foregroundColor: ThemeColor.get(context).primaryAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: ThemeColor.get(context).primaryAccent,
                  foregroundColor: Colors.white),
              onPressed: () async {
                // Call api to delete category
                await api<CategoryApiService>(
                    (request) => request.deleteCategory(categoryId));
                Navigator.of(context).pop();
                _pagingController.refresh();
              },
              child: Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}
