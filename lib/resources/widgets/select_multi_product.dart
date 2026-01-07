import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/product/edit_product_page.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ProductMultiSelect extends NyStatefulWidget {
  final GlobalKey<DropdownSearchState<Product>> multiKey;
  final void Function(List<Product>? products) onSelect;
  final List<Product> selectedItems;
  final String confirmText;
  bool? isShowList = true;

  ProductMultiSelect({
    Key? key,
    required this.multiKey,
    required this.onSelect,
    required this.selectedItems,
    this.isShowList,
    this.confirmText = 'Tiếp tục',
  });

  @override
  NyState<ProductMultiSelect> createState() => ProductMultiSelectState();
}

class ProductMultiSelectState extends NyState<ProductMultiSelect> {
  static const _pageSize = 10;
  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 1);
  String keyword = '';
  TextEditingController searchBoxController = TextEditingController();
  List<Product> listItemsSelectedTmp = [];
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
      var res = await api<ProductApiService>((request) => request.listProduct(
            keyword.isEmpty ? null : keyword,
            pageKey,
            _pageSize,
          ));
      List<Product> productItems =
          res['data'].map<Product>((data) => Product.fromJson(data)).toList();
      listItemsSelectedTmp = [...widget.selectedItems];
      for (var item in productItems) {
        var i = listItemsSelectedTmp
            .firstWhereOrNull((element) => element.id == item.id);
        if (i != null) {
          item.isSelected = true;
        } else {
          item.isSelected = false;
        }
      }
      final isLastPage = productItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(productItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(productItems, nextPageKey);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownSearch<Product>(
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
              constraints: BoxConstraints(maxHeight: 0.8.sh),
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
                                  'Chọn món ăn',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
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
                                    hintText: "Tên món ăn",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color:
                                          ThemeColor.get(context).primaryAccent,
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
                                        EditProductPage.path,
                                        onPop: (value) {
                                          if (value != null) {
                                            _pagingController.refresh();
                                          }
                                        },
                                      );
                                    },
                                    child: Icon(FontAwesomeIcons.plus,
                                        color: ThemeColor.get(context)
                                            .primaryAccent)))
                          ],
                        ),
                      ),
                      Expanded(
                        child: PagedGridView<int, Product>(
                          pagingController: _pagingController,
                          padding: EdgeInsets.all(12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          builderDelegate: PagedChildBuilderDelegate<Product>(
                            firstPageErrorIndicatorBuilder: (context) => Center(
                              child: Text(
                                  getResponseError(_pagingController.error)),
                            ),
                            newPageErrorIndicatorBuilder: (context) => Center(
                              child: Text(
                                  getResponseError(_pagingController.error)),
                            ),
                            firstPageProgressIndicatorBuilder: (context) =>
                                Center(child: AppLoading()),
                            newPageProgressIndicatorBuilder: (context) =>
                                Center(child: AppLoading()),
                            itemBuilder: (context, item, index) =>
                                buildPopupItem(context, item),
                            noItemsFoundIndicatorBuilder: (_) => Center(
                                child: Text("Không tìm thấy món ăn nào")),
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
              labelText: 'Chọn món ăn',
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPopupItem(BuildContext context, Product item) {
    bool isSelected = listItemsSelectedTmp
            .firstWhereOrNull((element) => element.id == item.id) !=
        null;

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            listItemsSelectedTmp
                .removeWhere((element) => element.id == item.id);
          } else {
            listItemsSelectedTmp.add(item);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeColor.get(context).primaryAccent.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ThemeColor.get(context).primaryAccent
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10)),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[200],
                      child: item.image != null && item.image!.isNotEmpty
                          ? Image.network(
                              item.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                      'public/assets/images/placeholder.png',
                                      fit: BoxFit.cover),
                            )
                          : Image.asset('public/assets/images/placeholder.png',
                              fit: BoxFit.cover),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: ThemeColor.get(context).primaryAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 5,
                    child: Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white),
                        child: Text(
                          vnd.format(item.retailCost ?? 0),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: ThemeColor.get(context).primaryAccent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  item.name ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isSelected
                        ? ThemeColor.get(context).primaryAccent
                        : Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: ThemeColor.get(context).primaryAccent,
                      minimumSize: Size(80, 48)),
                  onPressed: () {
                    keyword = '';
                    Navigator.pop(context);
                    addMultiItems(listItemsSelectedTmp);
                    setState(() {
                      listItemsSelectedTmp.clear();
                    });
                  },
                  child: Text(
                    '${widget.confirmText} (${listItemsSelectedTmp.length})',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  )),
            ),
          ],
        ));
  }

  void addMultiItems(List<Product> items) {
    if (items.isEmpty) {
      widget.selectedItems.clear();
      widget.onSelect(widget.selectedItems);
      return;
    }

    for (var item in items) {
      if (widget.selectedItems.indexWhere((element) => element.id == item.id) ==
          -1) {
        // Initialize new product
        item.quantity = 1;
        item.txtQuantity.text = '1';
        item.txtPrice.text = vnd.format(item.retailCost ?? 0);
        item.txtDiscount.text = '0';
        item.discount = 0;
        item.discountType = DiscountType.percent;
        setState(() {
          widget.selectedItems.add(item);
        });
      }
    }

    widget.selectedItems.removeWhere((i) {
      final isStillSelected =
          items.indexWhere((element) => element.id == i.id) != -1;
      return !isStillSelected;
    });

    widget.onSelect(widget.selectedItems);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    searchBoxController.dispose();
    super.dispose();
  }
}
