import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/Supplier.dart';
import 'package:flutter_app/app/networking/supplier_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/Supplier/edit_Supplier_page.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListSupplierPage extends NyStatefulWidget {
  static const path = '/suppliers';
  ListSupplierPage({super.key});

  @override
  NyState<ListSupplierPage> createState() => _ListSupplierPageState();
}

class _ListSupplierPageState extends NyState<ListSupplierPage> {
  final PagingController<int, Supplier> _pagingController =
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
      Map<String, dynamic> res = await api<SupplierApiService>(
          (request) => request.listSupplier(searchQuery, pageKey, _pageSize));

      setState(() {
        List<Supplier> items = [];
        final data = res['data'] as List<dynamic>? ?? [];
        data.forEach((item) => items.add(Supplier.fromJson(item)));

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

  Widget buildItem(Supplier item) {
    return Column(
      children: [
        InkWell(
          onTap: () =>
              routeTo(EditSupplierPage.path, data: {'data': item}, onPop: (_) {
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

  Widget _buildAvatar(Supplier item) {
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

  Widget _buildItemInfo(Supplier item) {
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

  Widget _buildPopupMenu(Supplier item) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
      onSelected: (value) async {
        if (value == 'edit') {
          routeTo(EditSupplierPage.path, data: {'data': item}, onPop: (_) {
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

  void _showDeleteConfirmationDialog(Supplier item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content:
              const Text('Bạn có chắc chắn muốn xóa nhà cung cấp này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await api<SupplierApiService>(
                      (request) => request.deleteSupplier(item.id!));
                  CustomToast.showToastSuccess(context,
                      description: 'Xóa nhà cung cấp thành công');
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
        title: const Text('Danh sách nhà cung cấp',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              routeTo(EditSupplierPage.path, onPop: (_) {
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
                hintText: 'Tìm kiếm nhà cung cấp',
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
                      child: Text('Không tìm thấy nhà cung cấp nào')),
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
