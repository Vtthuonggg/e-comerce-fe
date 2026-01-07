import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/report_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:intl/intl.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ProductSalesReportPage extends NyStatefulWidget {
  static const path = '/product-sales-report';
  ProductSalesReportPage({super.key});

  @override
  NyState<ProductSalesReportPage> createState() =>
      _ProductSalesReportPageState();
}

class _ProductSalesReportPageState extends NyState<ProductSalesReportPage> {
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
        (request) => request.getProductSalesReport(
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
          'Thống kê bán hàng',
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
          : RefreshIndicator(
              onRefresh: _fetchReport,
              color: accent,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range
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
                          Icon(Icons.arrow_forward_ios,
                              color: accent, size: 16),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    if (reportData != null) ...[
                      Text(
                        'Danh sách sản phẩm đã bán',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(reportData['products'] as List).length} sản phẩm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      if ((reportData['products'] as List).isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 64, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có sản phẩm nào được bán',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: (reportData['products'] as List).length,
                          itemBuilder: (context, index) {
                            final product = reportData['products'][index];
                            return _buildProductCard(product, index + 1);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductCard(dynamic product, int rank) {
    final accent = ThemeColor.get(context).primaryAccent;
    final totalQuantity = product['total_quantity'] ?? 0;
    final totalRevenue = product['total_revenue'] ?? 0;
    final orderCount = product['order_count'] ?? 0;

    Color rankColor = Colors.grey;
    IconData rankIcon = Icons.filter_none;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.workspace_premium;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.workspace_premium;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
      rankIcon = Icons.workspace_premium;
    }

    return Card(
      elevation: 0.5,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: rank <= 3
                        ? Icon(rankIcon, color: rankColor, size: 24)
                        : Text(
                            '#$rank',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: rankColor,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['product_name'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Xuất hiện trong $orderCount đơn hàng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Stats
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2,
                                size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              'Số lượng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          roundQuantity(totalQuantity),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Doanh thu',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          vnd.format(totalRevenue),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
