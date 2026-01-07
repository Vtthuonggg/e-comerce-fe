import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/order/detail_order_page.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_app/resources/widgets/single_tap_detector.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

final Map<int, String> orderStatus = {
  1: 'Hoàn thành',
  2: 'Chờ xác nhận',
};

final Map<int, Color> orderStatusColor = {
  1: Colors.green,
  2: Colors.orange,
};

class OrderListAllPage extends NyStatefulWidget {
  static const path = '/order-list-all';
  OrderListAllPage({super.key});

  @override
  NyState<OrderListAllPage> createState() => _OrderListAllPageState();
}

class _OrderListAllPageState extends NyState<OrderListAllPage> {
  int selectedTabIndex = 0;
  static const _pageSize = 20;

  final PageController pageController =
      PageController(initialPage: 0, keepPage: true);
  final PagingController<int, dynamic> _pagingOrderController =
      PagingController(firstPageKey: 1);
  final PagingController<int, dynamic> _pagingStorageController =
      PagingController(firstPageKey: 1);

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  String searchQuery = '';

  bool get _isStoragePage => selectedTabIndex == 0;
  bool get _isOrderPage => selectedTabIndex == 1;

  @override
  void initState() {
    super.initState();
    _pagingOrderController.addPageRequestListener((pageKey) {
      _fetchOrderPage(pageKey);
    });
    _pagingStorageController.addPageRequestListener((pageKey) {
      _fetchStoragePage(pageKey);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    _pagingOrderController.dispose();
    _pagingStorageController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderPage(int pageKey) async {
    try {
      dynamic result = await api<OrderApiService>(
        (request) =>
            request.listOrder(searchQuery, pageKey, _pageSize, type: 1),
      );
      List<dynamic> newItems = result['data'];
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingOrderController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingOrderController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingOrderController.error = error;
    }
  }

  Future<void> _fetchStoragePage(int pageKey) async {
    try {
      dynamic result = await api<OrderApiService>((request) =>
          request.listOrder(searchQuery, pageKey, _pageSize, type: 2));
      List<dynamic> newItems = result['data'];
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingStorageController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingStorageController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingStorageController.error = error;
    }
  }

  void _jumpToPage(int index) {
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 50),
      curve: Curves.linear,
    );
  }

  void _debounceSearch() {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _handleSearch();
    });
  }

  void _handleSearch() {
    if (_isOrderPage) {
      _pagingOrderController.refresh();
    } else if (_isStoragePage) {
      _pagingStorageController.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Scaffold(
      appBar: GradientAppBar(
        title: Text('Quản lý đơn hàng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Row(
              children: [
                Expanded(
                  child: SingleTapDetector(
                    onTap: () {
                      setState(() {
                        selectedTabIndex = 0;
                        _jumpToPage(0);
                      });
                    },
                    child: Container(
                      height: 45,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: ThemeColor.get(context).primaryAccent),
                        color: selectedTabIndex == 0
                            ? Colors.white
                            : ThemeColor.get(context).primaryAccent,
                      ),
                      child: Center(
                        child: Text(
                          'Nhập',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedTabIndex == 0
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleTapDetector(
                    onTap: () {
                      setState(() {
                        selectedTabIndex = 1;
                        _jumpToPage(1);
                      });
                    },
                    child: Container(
                      height: 45,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: ThemeColor.get(context).primaryAccent),
                        color: selectedTabIndex == 1
                            ? Colors.white
                            : ThemeColor.get(context).primaryAccent,
                      ),
                      child: Center(
                        child: Text(
                          'Bán',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedTabIndex == 1
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Search Bar
            _buildSearchBar(context),
            SizedBox(height: 12),
            // Content
            Expanded(
              child: PageView(
                controller: pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildStoragePage(),
                  _buildOrderPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        keyboardType: TextInputType.text,
        controller: searchController,
        onChanged: (value) {
          searchQuery = value;
          _debounceSearch();
        },
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        textAlign: TextAlign.left,
        cursorColor: ThemeColor.get(context).primaryAccent,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = '';
                    });
                    _handleSearch();
                  },
                )
              : null,
          hintText: 'Lọc đơn hàng',
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: ThemeColor.get(context).primaryAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildStoragePage() {
    return RefreshIndicator(
      color: ThemeColor.get(context).primaryAccent,
      onRefresh: () => Future.sync(() => _pagingStorageController.refresh()),
      child: PagedListView<int, dynamic>(
        pagingController: _pagingStorageController,
        builderDelegate: PagedChildBuilderDelegate<dynamic>(
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: Text(getResponseError(_pagingStorageController.error)),
          ),
          newPageErrorIndicatorBuilder: (context) => Center(
            child: Text(getResponseError(_pagingStorageController.error)),
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
          itemBuilder: (context, item, index) => _buildStorageItem(item),
          noItemsFoundIndicatorBuilder: (_) =>
              Center(child: const Text("Không tìm thấy đơn nào")),
        ),
      ),
    );
  }

  Widget _buildOrderPage() {
    return RefreshIndicator(
      color: ThemeColor.get(context).primaryAccent,
      onRefresh: () => Future.sync(() => _pagingOrderController.refresh()),
      child: PagedListView<int, dynamic>(
        pagingController: _pagingOrderController,
        builderDelegate: PagedChildBuilderDelegate<dynamic>(
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: Text(getResponseError(_pagingOrderController.error)),
          ),
          newPageErrorIndicatorBuilder: (context) => Center(
            child: Text(getResponseError(_pagingOrderController.error)),
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
          itemBuilder: (context, item, index) => _buildOrderItem(item),
          noItemsFoundIndicatorBuilder: (_) =>
              Center(child: const Text("Không tìm thấy đơn nào")),
        ),
      ),
    );
  }

  Widget _buildStorageItem(dynamic item) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            routeTo(DetailOrderPage.path, data: {'id': item['id']});
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 15),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['supplier']?['name'] ?? 'Đại lý',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Mã: #${item['id']}",
                      ),
                      Text(
                        "Ngày nhập: ${formatDate(item['created_at'])}",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        "Sản phẩm: ${item['order_detail']?.length ?? 0}",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatus(item['status_order']),
                    SizedBox(height: 4),
                    Text(
                      vnd.format(item['total_amount'] ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: Colors.grey[300], height: 1),
        ),
      ],
    );
  }

  Widget _buildOrderItem(dynamic item) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            routeTo(DetailOrderPage.path, data: {'id': item['id']});
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 15),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['customer']?['name'] ?? 'Khách lẻ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Mã: #${item['id']}",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      if (item['room'] != null)
                        Text(
                          "Vị trí: ${item['room']?['area']?['name'] ?? ''} - ${item['room']?['name'] ?? ''}",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      Text(
                        "Ngày bán: ${formatDate(item['created_at'])}",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        "Sản phẩm: ${item['order_detail']?.length ?? 0}",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatus(item['status_order']),
                    SizedBox(height: 4),
                    Text(
                      vnd.format(item['total_amount'] ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    if (item['payment']?['type'] != null)
                      Text(
                        _getPaymentTypeText(item['payment']['type']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: Colors.grey[300], height: 1),
        ),
      ],
    );
  }

  Widget _buildStatus(int status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (orderStatusColor[status] ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: orderStatusColor[status] ?? Colors.grey,
          width: 1,
        ),
      ),
      child: Text(
        orderStatus[status] ?? 'Không xác định',
        style: TextStyle(
          color: orderStatusColor[status] ?? Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getPaymentTypeText(int type) {
    switch (type) {
      case 1:
        return 'Tiền mặt';
      case 2:
        return 'Chuyển khoản';
      case 3:
        return 'Quẹt thẻ';
      default:
        return '';
    }
  }
}
