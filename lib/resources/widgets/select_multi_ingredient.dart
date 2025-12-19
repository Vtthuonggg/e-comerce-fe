import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/networking/ingredient_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/ingredient/edit_ingredient_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class IngredientMultiSelect extends NyStatefulWidget {
  final GlobalKey<DropdownSearchState<Ingredient>> multiKey;
  final void Function(List<Ingredient>? variant) onSelect;
  final List<Ingredient> selectedItems;
  final String confirmText;
  bool? isShowList = true;
  IngredientMultiSelect({
    Key? key,
    required this.multiKey,
    required this.onSelect,
    required this.selectedItems,
    this.isShowList,
    this.confirmText = 'Tiếp tục',
  });

  @override
  NyState<IngredientMultiSelect> createState() => IngredientMultiSelectState();
}

class IngredientMultiSelectState extends NyState<IngredientMultiSelect> {
  static const _pageSize = 10;
  final PagingController<int, Ingredient> _pagingController =
      PagingController(firstPageKey: 1);
  String keyword = '';
  TextEditingController searchBoxController = TextEditingController();
  List<Ingredient> listItemsSelectedTmp = [];
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
      var res =
          await api<IngredientApiService>((request) => request.listIngredient(
                keyword.isEmpty ? null : keyword,
                pageKey,
                _pageSize,
              ));
      List<Ingredient> ingredientItems = res['data']
          .map<Ingredient>((data) => Ingredient.fromJson(data))
          .toList();
      listItemsSelectedTmp = [...widget.selectedItems];
      for (var item in ingredientItems) {
        var i = listItemsSelectedTmp
            .firstWhereOrNull((element) => element.id == item.id);
        if (i != null) {
          item.isSelected = true;
        } else {
          item.isSelected = false;
        }
      }
      final isLastPage = ingredientItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(ingredientItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(ingredientItems, nextPageKey);
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
        DropdownSearch<Ingredient>(
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
                                  'Chọn nguyên liệu',
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
                                    hintText: "Tên nguyên liệu",
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
                                        EditIngredientPage.path,
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
                        child: PagedListView<int, Ingredient>(
                          pagingController: _pagingController,
                          builderDelegate:
                              PagedChildBuilderDelegate<Ingredient>(
                            firstPageErrorIndicatorBuilder: (context) => Center(
                              child: Text(
                                  getResponseError(_pagingController.error)),
                            ),
                            newPageErrorIndicatorBuilder: (context) => Center(
                              child: Text(
                                  getResponseError(_pagingController.error)),
                            ),
                            firstPageProgressIndicatorBuilder: (context) =>
                                Center(
                              child: CircularProgressIndicator(
                                color: ThemeColor.get(context).primaryAccent,
                              ),
                            ),
                            newPageProgressIndicatorBuilder: (context) =>
                                Center(
                              child: CircularProgressIndicator(
                                color: ThemeColor.get(context).primaryAccent,
                              ),
                            ),
                            itemBuilder: (context, item, index) =>
                                buildPopupItem(context, item),
                            noItemsFoundIndicatorBuilder: (_) => Center(
                                child: Text("Không tìm thấy nguyên liệu nào")),
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
              labelText: 'Chọn nguyên liệu',
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
        if (widget.selectedItems.isNotEmpty && widget.isShowList == true) ...[
          SizedBox(height: 16),
          Text(
            'Nguyên liệu đã chọn:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          ...widget.selectedItems
              .map((ingredient) => buildSelectedIngredientItem(ingredient)),
        ],
      ],
    );
  }

  Widget buildSelectedIngredientItem(Ingredient ingredient) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Ảnh nguyên liệu
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: ingredient.image != null && ingredient.image!.isNotEmpty
                ? Image.network(
                    ingredient.image!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[200],
                      child:
                          Image.asset('public/assets/images/placeholder.png'),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[200],
                    child: Image.asset('public/assets/images/placeholder.png'),
                  ),
          ),
          SizedBox(width: 12),
          // Tên nguyên liệu
          Expanded(
            child: Text(
              ingredient.name ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          // Input số lượng và unit
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: ingredient.quantity != null
                  ? ingredient.quantity.toString()
                  : '',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  ingredient.quantity = stringToDouble(value) ?? 0;
                });
              },
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                hintText: '0',
                hintStyle: TextStyle(fontSize: 12),
              ),
              style: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(width: 8),
          Text(
            ingredient.unit ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8),
          // Nút xóa
          InkWell(
            onTap: () {
              setState(() {
                widget.selectedItems
                    .removeWhere((item) => item.id == ingredient.id);
                ingredient.quantity = 0;
              });
              widget.onSelect(widget.selectedItems);
            },
            child: Icon(
              Icons.remove_circle_outline,
              color: Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPopupItem(BuildContext context, Ingredient item) {
    bool isSelected = listItemsSelectedTmp
            .firstWhereOrNull((element) => element.id == item.id) !=
        null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? ThemeColor.get(context).primaryAccent.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? ThemeColor.get(context).primaryAccent.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
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
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: item.image != null && item.image!.isNotEmpty
                ? Image.network(
                    item.image!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child:
                          Image.asset('public/assets/images/placeholder.png'),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: Image.asset('public/assets/images/placeholder.png'),
                  ),
          ),
          title: Text(
            item.name!.length > 25
                ? item.name!.substring(0, 25) + '...'
                : item.name!,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? ThemeColor.get(context).primaryAccent
                  : Colors.grey[800],
            ),
          ),
          subtitle: Text('Tồn kho: ${item.inStock}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vnd.format(item.baseCost ?? 0),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (item.unit != null && item.unit!.isNotEmpty) ...[
                Text('ĐV: ${item.unit}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]))
              ]
            ],
          )),
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

  void addMultiItems(List<Ingredient> items) {
    if (items.isEmpty) {
      widget.selectedItems.clear();
      widget.onSelect(widget.selectedItems);
      return;
    }

    for (var item in items) {
      if (widget.selectedItems.indexWhere((element) => element.id == item.id) ==
          -1) {
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
