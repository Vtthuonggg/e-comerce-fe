import 'dart:async';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/supplier.dart';
import 'package:flutter_app/app/networking/supplier_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/supplier/edit_supplier_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class SupplierSelect extends NyStatefulWidget {
  final GlobalKey<DropdownSearchState<Supplier>> selectKey;
  final void Function(Supplier? supplier) onSelect;
  final Supplier? selectedItem;
  final String? labelText;
  final String? hintText;

  SupplierSelect({
    Key? key,
    required this.selectKey,
    required this.onSelect,
    this.selectedItem,
    this.labelText = 'Chọn nhà cung cấp',
    this.hintText = 'Chọn nhà cung cấp',
  }) : super(key: key);

  @override
  NyState<SupplierSelect> createState() => _SupplierSelectState();
}

class _SupplierSelectState extends NyState<SupplierSelect> {
  static const _pageSize = 10;
  final PagingController<int, Supplier> _pagingController =
      PagingController(firstPageKey: 1);
  String keyword = '';
  TextEditingController searchBoxController = TextEditingController();
  Supplier? selectedItemTmp;
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
      var res = await api<SupplierApiService>((request) => request.listSupplier(
          keyword.isEmpty ? null : keyword, pageKey, _pageSize));
      List<Supplier> supplierItems =
          res['data'].map<Supplier>((data) => Supplier.fromJson(data)).toList();

      final isLastPage = supplierItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(supplierItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(supplierItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        keyword = value;
      });
      _pagingController.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return DropdownSearch<Supplier>(
      key: widget.selectKey,
      onBeforePopupOpening: (value) async {
        searchBoxController.text = '';
        keyword = '';
        selectedItemTmp = widget.selectedItem;
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
                topRight: Radius.circular(20.w),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.09),
                  offset: const Offset(0, -13),
                  blurRadius: 31,
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        margin: EdgeInsets.all(16.w),
                        child: Text(
                          widget.labelText ?? 'Chọn nhà cung cấp',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0.w,
                      top: 0.h,
                      child: IconButton(
                        icon: Icon(Icons.close, size: 20.w),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
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
                            onChanged: _onSearchChanged,
                            controller: searchBoxController,
                            cursorColor: ThemeColor.get(context).primaryAccent,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm nhà cung cấp...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: ThemeColor.get(context).primaryAccent,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: ThemeColor.get(context).primaryAccent,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: ThemeColor.get(context).primaryAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                routeTo(EditSupplierPage.path, onPop: (value) {
                                  _pagingController.refresh();
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ThemeColor.get(context).primaryAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  FontAwesomeIcons.plus,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PagedListView<int, Supplier>(
                    pagingController: _pagingController,
                    builderDelegate: PagedChildBuilderDelegate<Supplier>(
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
                          buildPopupItem(context, item),
                      noItemsFoundIndicatorBuilder: (_) => Center(
                        child: Text("Không tìm thấy nhà cung cấp nào"),
                      ),
                    ),
                  ),
                ),
                buildPopupSelect(context),
              ],
            ),
          );
        },
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          suffixIcon: widget.selectedItem != null
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    widget.onSelect(null);
                  },
                )
              : null,
        ),
      ),
      onChanged: (Supplier? value) {},
      selectedItem: widget.selectedItem,
      itemAsString: (Supplier supplier) => supplier.name ?? 'Không có tên',
    );
  }

  Widget buildPopupItem(BuildContext context, Supplier item) {
    bool isSelected = selectedItemTmp?.id == item.id;

    final String initials = (item.name ?? '')
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();

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
            selectedItemTmp = item;
          });
        },
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade50,
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: TextStyle(
              color: isSelected
                  ? ThemeColor.get(context).primaryAccent
                  : Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          item.name ?? 'Không có tên',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected
                ? ThemeColor.get(context).primaryAccent
                : Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.phone != null && item.phone!.isNotEmpty)
              Text(
                'SĐT: ${item.phone}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (item.address != null && item.address!.isNotEmpty)
              Text(
                item.address!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? ThemeColor.get(context).primaryAccent
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            isSelected ? Icons.check : Icons.circle_outlined,
            color: isSelected ? Colors.white : Colors.grey[500],
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
                backgroundColor: ThemeColor.get(context).primaryAccent,
                minimumSize: Size(80, 40),
              ),
              onPressed: () {
                keyword = '';
                Navigator.pop(context);
                widget.onSelect(selectedItemTmp);
              },
              child: Text(
                'Xác nhận',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    searchBoxController.dispose();
    super.dispose();
  }
}
