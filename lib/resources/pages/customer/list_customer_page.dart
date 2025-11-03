import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/customer.dart';
import 'package:flutter_app/app/networking/customer_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/customer/edit_customer_page.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListCustomerPage extends NyStatefulWidget {
  static const path = '/customers';
  ListCustomerPage({super.key});

  @override
  NyState<ListCustomerPage> createState() => _ListCustomerPageState();
}

class _ListCustomerPageState extends NyState<ListCustomerPage> {
  final PagingController<int, Customer> _pagingController =
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

  Future<void> _fetchData(int pageKey) async {
    try {
      Map<String, dynamic> res = await api<CustomerApiService>(
          (request) => request.listCustomer(searchQuery, pageKey, _pageSize));

      setState(() {
        List<Customer> items = [];
        final data = res['data'] as List<dynamic>? ?? [];
        data.forEach((item) => items.add(Customer.fromJson(item)));

        final isLastPage = items.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(items);
        } else {
          _pagingController.appendPage(items, pageKey + 1);
        }

        _total = res['meta']?['total'];
      });
    } catch (error) {
      log(error.toString());
      _pagingController.error = error;
    }
  }

  Widget buildItem(Customer item) {
    return Column(
      children: [
        InkWell(
          onTap: () =>
              routeTo(EditCustomerPage.path, data: {'data': item}, onPop: (_) {
            _pagingController.refresh();
          }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAvatar(item),
                const SizedBox(width: 16),
                Expanded(child: _buildItemInfo(item)),
                _buildPopupMenu(item),
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

  Widget _buildAvatar(Customer item) {
    final String initials = (item.name ?? '')
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue.shade50,
      child: Text(initials.isEmpty ? '?' : initials,
          style: TextStyle(color: Colors.blue.shade700)),
    );
  }

  Widget _buildItemInfo(Customer item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name ?? 'Không có tên',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        if (item.phone != null && item.phone!.isNotEmpty)
          Text('SĐT: ${item.phone}', style: TextStyle(color: Colors.grey[700])),
        if (item.address != null && item.address!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(item.address!, style: TextStyle(color: Colors.grey[700])),
        ],
      ],
    );
  }

  Widget _buildPopupMenu(Customer item) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
      onSelected: (value) async {
        if (value == 'edit') {
          routeTo(EditCustomerPage.path, data: {'data': item}, onPop: (_) {
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
              Icon(Icons.edit, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Sửa'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Xóa'),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(Customer item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content:
              const Text('Bạn có chắc chắn muốn xóa khách hàng này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await api<CustomerApiService>(
                      (request) => request.deleteCustomer(item.id!));
                  CustomToast.showToastSuccess(context,
                      description: 'Xóa khách hàng thành công');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Danh sách khách hàng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              routeTo(EditCustomerPage.path, onPop: (_) {
                _pagingController.refresh();
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _pagingController.refresh();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khách hàng',
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
                Text('Tổng: $_total'),
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
                  noItemsFoundIndicatorBuilder: (_) => const Center(
                      child: Text('Không tìm thấy khách hàng nào')),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
