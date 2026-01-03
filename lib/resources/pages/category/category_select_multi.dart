import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:flutter_app/app/networking/category_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/category/edit_category_page.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class CategorytMultiSelect extends NyStatefulWidget {
  final GlobalKey<DropdownSearchState<CategoryModel>> multiKey;
  final void Function(List<CategoryModel>? variant) onSelect;
  final List<CategoryModel> selectedItems;
  final String confirmText;

  CategorytMultiSelect({
    Key? key,
    required this.multiKey,
    required this.onSelect,
    required this.selectedItems,
    this.confirmText = 'Tiếp tục',
  });

  @override
  NyState<CategorytMultiSelect> createState() => CategorytMultiSelectState();
}

class CategorytMultiSelectState extends NyState<CategorytMultiSelect> {
  static const _pageSize = 10;
  final PagingController<int, CategoryModel> _pagingController =
      PagingController(firstPageKey: 1);
  String keyword = '';
  TextEditingController searchBoxController = TextEditingController();
  List<CategoryModel> listItemsSelectedTmp = [];
  Timer? _debounce;
  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  _fetchPage(int pageKey) async {
    try {
      var res = await api<CategoryApiService>((request) => request.listCategory(
            keyword,
            pageKey,
            _pageSize,
          ));
      List<CategoryModel> categoryItems = res['data']
          .map<CategoryModel>((data) => CategoryModel.fromJson(data))
          .toList();
      listItemsSelectedTmp = [...widget.selectedItems];
      for (var item in categoryItems) {
        var i = listItemsSelectedTmp
            .firstWhereOrNull((element) => element.id == item.id);
        if (i != null) {
          item.isSelected = true;
        }
      }
      final isLastPage = categoryItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(categoryItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(categoryItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
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
    ScreenUtil.init(context);
    return DropdownSearch<CategoryModel>(
      key: widget.multiKey,
      onBeforePopupOpening: (value) async {
        searchBoxController.text = '';
        keyword = '';
        listItemsSelectedTmp = [...widget.selectedItems];
        _pagingController.refresh();
        FocusManager.instance.primaryFocus?.unfocus();
        return true;
      },
      popupProps: PopupProps.modalBottomSheet(
          constraints: BoxConstraints(maxHeight: 0.7.sh),
          containerBuilder: (context, popupWidget) {
            return Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.w),
                      topRight: Radius.circular(20.w)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        offset: const Offset(0, -13),
                        blurRadius: 31),
                  ]),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Align(
                          alignment: Alignment.center,
                          child: Container(
                            margin: EdgeInsets.all(16.w),
                            child: Text(
                              'Chọn nhóm hàng',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          )),
                      Positioned(
                        right: 0.w,
                        top: 0.h,
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20.w,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 8,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 8.0, top: 8, bottom: 8),
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  keyword = value;
                                });
                                _debounceSearch();
                              },
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor:
                                  ThemeColor.get(context).primaryAccent,
                              decoration: InputDecoration(
                                hintText: "Tên nhóm hàng",
                                hintStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: ThemeColor.get(context).primaryAccent,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                            flex: 1,
                            child: InkWell(
                                onTap: () {
                                  routeTo(
                                    EditCategoryPage.path,
                                    onPop: (value) {
                                      if (value != null) {
                                        _pagingController.refresh();
                                      }
                                    },
                                  );
                                },
                                child: Icon(FontAwesomeIcons.plus,
                                    color:
                                        ThemeColor.get(context).primaryAccent)))
                      ],
                    ),
                  ),
                  Expanded(
                    child: PagedListView<int, CategoryModel>(
                      pagingController: _pagingController,
                      builderDelegate: PagedChildBuilderDelegate<CategoryModel>(
                        firstPageErrorIndicatorBuilder: (context) => Center(
                          child:
                              Text(getResponseError(_pagingController.error)),
                        ),
                        newPageErrorIndicatorBuilder: (context) => Center(
                          child:
                              Text(getResponseError(_pagingController.error)),
                        ),
                        firstPageProgressIndicatorBuilder: (context) =>
                            Center(child: AppLoading()),
                        newPageProgressIndicatorBuilder: (context) =>
                            Center(child: AppLoading()),
                        itemBuilder: (context, item, index) =>
                            buildPopupItem(context, item),
                        noItemsFoundIndicatorBuilder: (_) =>
                            Center(child: Text("Không tìm thấy nhóm hàng nào")),
                      ),
                    ),
                  ),
                  buildPopupSelect(context),
                ],
              ),
            );
          }),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          label: widget.selectedItems.isEmpty
              ? Text(
                  'Chọn nhóm hàng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: widget.selectedItems.map((item) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 5.0),
                        decoration: BoxDecoration(
                          color: ThemeColor.get(context)
                              .primaryAccent
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.name ?? '',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget buildPopupItem(BuildContext context, CategoryModel item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: item.isSelected
            ? ThemeColor.get(context).primaryAccent.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isSelected
              ? ThemeColor.get(context).primaryAccent.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            item.isSelected = !item.isSelected;
            if (item.isSelected) {
              listItemsSelectedTmp.add(item);
            } else {
              listItemsSelectedTmp
                  .removeWhere((element) => element.id == item.id);
            }
          });
        },
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.isSelected
                ? ThemeColor.get(context).primaryAccent.withOpacity(0.2)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.category,
            color: item.isSelected
                ? ThemeColor.get(context).primaryAccent
                : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          item.name!.length > 25
              ? item.name!.substring(0, 25) + '...'
              : item.name!,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: item.isSelected
                ? ThemeColor.get(context).primaryAccent
                : Colors.grey[800],
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: item.isSelected
                ? ThemeColor.get(context).primaryAccent
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            item.isSelected ? Icons.check : Icons.add,
            color: item.isSelected ? Colors.white : Colors.grey[500],
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget buildPopupSelect(BuildContext context) {
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    return Container(
        padding: shortestSide < 600
            ? EdgeInsets.all(16.w)
            : EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blue,
                      minimumSize: Size(80, 40)),
                  onPressed: () {
                    keyword = '';
                    Navigator.pop(context);
                    addMultiItems(listItemsSelectedTmp);
                    setState(() {
                      for (var item in listItemsSelectedTmp) {
                        item.isSelected = false;
                      }
                      listItemsSelectedTmp.clear();
                    });
                  },
                  child: Text(
                    widget.confirmText,
                    style: TextStyle(color: Colors.white),
                  )),
            ),
          ],
        ));
  }

  void addMultiItems(List<CategoryModel> items) {
    if (items.isEmpty) {
      for (var item in widget.selectedItems) {
        item.isSelected = false;
      }
      widget.selectedItems.clear();
      widget.onSelect(widget.selectedItems);
      return;
    }

    for (var item in items) {
      if (widget.selectedItems.indexWhere((element) => element.id == item.id) ==
          -1) {
        setState(() {
          item.isSelected = true;
          widget.selectedItems.add(item);
        });
      }
    }

    widget.selectedItems.removeWhere((i) {
      final isStillSelected =
          items.indexWhere((element) => element.id == i.id) != -1;
      if (!isStillSelected) {
        i.isSelected = false;
      }
      return !isStillSelected;
    });

    widget.onSelect(widget.selectedItems);
  }
}
