import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/report_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';

import 'package:intl/intl.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter_app/resources/pages/report/revenue_report_page.dart';
import 'package:flutter_app/resources/pages/report/product_sales_report_page.dart';
import 'package:flutter_app/resources/pages/report/ingredient_purchase_report_page.dart';

class ReportPage extends NyStatefulWidget {
  static const path = '/report';
  ReportPage({super.key});

  @override
  NyState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends NyState<ReportPage> {
  dynamic quickStats;
  dynamic dashboardData;
  bool _isLoading = true;
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results =
          await api<ReportApiService>((request) => request.getQuickStats());

      final results2 =
          await api<ReportApiService>((request) => request.getDashboardReport(
                startDate: DateFormat('yyyy-MM-dd').format(startDate),
                endDate: DateFormat('yyyy-MM-dd').format(endDate),
              ));

      setState(() {
        quickStats = results['data'];
        dashboardData = results2['data'];
        log(dashboardData.toString(), name: 'Dashboard Data');
        _isLoading = false;
      });
    } catch (e) {
      log(e.toString(), name: 'Error fetching report data');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeColor.get(context).primaryAccent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColor.get(context).primaryAccent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: accent,
        title: Text(
          'Báo cáo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: accent,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: accent))
            : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats
                    if (quickStats != null) _buildQuickStats(),
                    SizedBox(height: 24),

                    // Dashboard Report
                    Text(
                      'Tổng quan Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Date Range Selector
                    InkWell(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: accent, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Khoảng thời gian',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: accent, size: 16),
                          ],
                        ),
                      ),
                    ),

                    if (dashboardData != null) ...[
                      SizedBox(height: 16),
                      _buildDashboardReport(),
                    ],

                    SizedBox(height: 24),
                    // Report Categories
                    Text(
                      'Báo cáo chi tiết',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildReportGrid(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        _buildStatCard(
          title: 'Doanh thu hôm nay',
          value: vnd.format(quickStats['today']['revenue'] ?? 0),
          subtitle: DateFormat('dd/MM/yyyy').format(DateTime.now()),
          icon: Icons.today,
          color: Colors.blue,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
        ),
        SizedBox(height: 12),
        _buildStatCard(
          title: 'Doanh thu tuần này',
          value: vnd.format(quickStats['this_week']['revenue'] ?? 0),
          subtitle:
              'Từ ${DateFormat('dd/MM').format(DateTime.parse(quickStats['this_week']['start_date']))}',
          icon: Icons.date_range,
          color: Colors.green,
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
        ),
        SizedBox(height: 12),
        _buildStatCard(
          title: 'Doanh thu tháng này',
          value: vnd.format(quickStats['this_month']['revenue'] ?? 0),
          subtitle:
              'Từ ${DateFormat('dd/MM').format(DateTime.parse(quickStats['this_month']['start_date']))}',
          icon: Icons.calendar_month,
          color: Colors.orange,
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardReport() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                title: 'Doanh thu bán',
                value: vnd.format(dashboardData['total_revenue'] ?? 0),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildDashboardCard(
                title: 'Chi phí nhập',
                value: vnd.format(dashboardData['total_purchase_cost'] ?? 0),
                icon: Icons.trending_down,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                title: 'Lợi nhuận',
                value: vnd.format(dashboardData['profit'] ?? 0),
                icon: Icons.account_balance_wallet,
                color: dashboardData['profit'] >= 0 ? Colors.blue : Colors.red,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildDashboardCard(
                title: 'Đơn chờ',
                value: '${dashboardData['pending_orders'] ?? 0}',
                icon: Icons.pending_actions,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                title: 'Đơn bán',
                value: '${dashboardData['total_sales_orders'] ?? 0}',
                icon: Icons.shopping_cart,
                color: Colors.teal,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildDashboardCard(
                title: 'Đơn nhập',
                value: '${dashboardData['total_purchase_orders'] ?? 0}',
                icon: Icons.inventory,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReportGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildReportCard(
            title: 'Doanh thu',
            subtitle: 'Báo cáo doanh thu',
            icon: Icons.payments,
            color: Colors.blue,
            onTap: () => routeTo(RevenueReportPage.path),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildReportCard(
            title: 'Sản phẩm',
            subtitle: 'Thống kê bán hàng',
            icon: Icons.shopping_bag,
            color: Colors.green,
            onTap: () => routeTo(ProductSalesReportPage.path),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildReportCard(
            title: 'Nguyên liệu',
            subtitle: 'Thống kê nhập hàng',
            icon: Icons.inventory_2,
            color: Colors.orange,
            onTap: () => routeTo(IngredientPurchaseReportPage.path),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
