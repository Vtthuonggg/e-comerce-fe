// lib/resources/pages/report/revenue_report_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/report_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:intl/intl.dart';
import 'package:nylo_framework/nylo_framework.dart';

class RevenueReportPage extends NyStatefulWidget {
  static const path = '/revenue-report';
  RevenueReportPage({super.key});

  @override
  NyState<RevenueReportPage> createState() => _RevenueReportPageState();
}

class _RevenueReportPageState extends NyState<RevenueReportPage> {
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();
  dynamic reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final res = await api<ReportApiService>(
        (request) => request.getRevenueReport(
          startDate: DateFormat('yyyy-MM-dd').format(startDate),
          endDate: DateFormat('yyyy-MM-dd').format(endDate),
        ),
      );
      setState(() {
        reportData = res['data'];
        _isLoading = false;
      });
    } catch (e) {
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
      _fetchReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColor.get(context).primaryAccent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: accent,
        title: Text(
          'Báo cáo doanh thu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, color: Colors.white),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Selector
                  Container(
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
                        Icon(Icons.arrow_forward_ios, color: accent, size: 16),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  if (reportData != null) ...[
                    // Summary Cards
                    _buildSummaryCard(
                      title: 'Tổng doanh thu',
                      value: vnd.format(reportData['total_revenue'] ?? 0),
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    SizedBox(height: 12),
                    _buildSummaryCard(
                      title: 'Tổng giảm giá',
                      value: vnd.format(reportData['total_discount'] ?? 0),
                      icon: Icons.discount,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 12),
                    _buildSummaryCard(
                      title: 'Số đơn hàng',
                      value: '${reportData['total_orders'] ?? 0}',
                      icon: Icons.shopping_cart,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 12),
                    _buildSummaryCard(
                      title: 'Giá trị TB/đơn',
                      value: vnd.format(reportData['average_order_value'] ?? 0),
                      icon: Icons.analytics,
                      color: Colors.purple,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
