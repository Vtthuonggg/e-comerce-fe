import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/employee.dart';
import 'package:flutter_app/app/networking/employee_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/employee/edit_employee_page.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ListEmployeePage extends NyStatefulWidget {
  static const path = '/employees';
  final controller = Controller();

  ListEmployeePage({super.key});

  @override
  NyState<ListEmployeePage> createState() => _ListEmployeePageState();
}

class _ListEmployeePageState extends NyState<ListEmployeePage> {
  static const _pageSize = 10;
  final PagingController<int, Employee> _pagingController =
      PagingController(firstPageKey: 1);
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      var res = await api<EmployeeApiService>((request) => request.listEmployee(
          searchQuery.isEmpty ? null : searchQuery, pageKey, _pageSize));
      List<Employee> employees =
          res['data'].map<Employee>((data) => Employee.fromJson(data)).toList();

      final isLastPage = employees.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(employees);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(employees, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(
          'Danh sách nhân viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhân viên...',
                prefixIcon: Icon(IconsaxPlusLinear.search_normal_1),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: ThemeColor.get(context).primaryAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // List
          Expanded(
            child: PagedListView<int, Employee>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<Employee>(
                firstPageErrorIndicatorBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconsaxPlusLinear.info_circle,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        getResponseError(_pagingController.error),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _pagingController.refresh(),
                        child: Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                newPageErrorIndicatorBuilder: (context) => Center(
                  child: TextButton(
                    onPressed: () => _pagingController.retryLastFailedRequest(),
                    child: Text('Thử lại'),
                  ),
                ),
                firstPageProgressIndicatorBuilder: (context) =>
                    Center(child: AppLoading()),
                newPageProgressIndicatorBuilder: (context) => Center(
                  child:
                      Padding(padding: EdgeInsets.all(16), child: AppLoading()),
                ),
                itemBuilder: (context, item, index) => _buildEmployeeCard(item),
                noItemsFoundIndicatorBuilder: (_) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconsaxPlusLinear.user_search,
                          size: 80, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        searchQuery.isEmpty
                            ? 'Chưa có nhân viên nào'
                            : 'Không tìm thấy nhân viên',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (searchQuery.isEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          'Nhấn nút + để thêm nhân viên mới',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          routeTo(EditEmployeePage.path, onPop: (value) {
            if (value == true) {
              _pagingController.refresh();
            }
          });
        },
        backgroundColor: ThemeColor.get(context).primaryAccent,
        icon: Icon(IconsaxPlusLinear.add, color: Colors.white),
        label: Text(
          'Thêm nhân viên',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        onTap: () {
          routeTo(EditEmployeePage.path, data: employee, onPop: (value) {
            if (value == true) {
              _pagingController.refresh();
            }
          });
        },
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: ThemeColor.get(context).primaryAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            IconsaxPlusLinear.user,
            color: ThemeColor.get(context).primaryAccent,
            size: 28,
          ),
        ),
        title: Text(
          employee.name ?? 'Chưa có tên',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: employee.phone != null && employee.phone!.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(IconsaxPlusLinear.call,
                        size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      employee.phone!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : null,
        trailing: Icon(
          IconsaxPlusLinear.arrow_right_3,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
