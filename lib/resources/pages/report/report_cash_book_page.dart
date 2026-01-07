import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/report_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:intl/intl.dart';
import 'package:nylo_framework/nylo_framework.dart';

class ReportCashBookPage extends NyStatefulWidget {
  static const path = '/report-cash-book';
  ReportCashBookPage({super.key});

  @override
  NyState<ReportCashBookPage> createState() => _ReportCashBookPageState();
}

class _ReportCashBookPageState extends NyState<ReportCashBookPage> {
  bool _isLoading = false;
  List<dynamic> transactions = [];
  Map<String, dynamic> meta = {};

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await api<ReportApiService>((request) => request.reportCashBook(
                startDate: startDate != null
                    ? DateFormat('yyyy-MM-dd').format(startDate!)
                    : null,
                endDate: endDate != null
                    ? DateFormat('yyyy-MM-dd').format(endDate!)
                    : null,
              ));

      setState(() {
        transactions = response['data'] ?? [];
        meta = response['meta'] ?? {};
      });
    } catch (error) {
      CustomToast.showToastError(context, description: getResponseError(error));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: GradientAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sổ quỹ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReport,
        child: _isLoading
            ? Center(child: AppLoading())
            : Column(
                children: [
                  SizedBox(height: 16),
                  _buildSummaryHeader(),
                  Expanded(
                    child: transactions.isEmpty
                        ? _buildEmptyState()
                        : _buildTransactionList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final totalIncome = meta['total_income'] ?? 0;
    final totalExpense = meta['total_expense'] ?? 0;
    final netProfit = meta['net_profit'] ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeColor.get(context).primaryAccent,
            ThemeColor.get(context).primaryAccent.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeColor.get(context).primaryAccent.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'Tổng thu',
                  amount: totalIncome,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Tổng chi',
                  amount: totalExpense,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.3), height: 1),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Lợi nhuận ròng: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                vndCurrency.format(netProfit),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required num amount,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          vndCurrency.format(amount),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(dynamic transaction) {
    final type = transaction['type'];
    final isIncome = type == 1;
    final typeName = transaction['type_name'] ?? '';
    final amount = transaction['amount'] ?? 0;
    final name = transaction['name'] ?? (isIncome ? 'Khách lẻ' : 'Đại lý');
    final paymentTypeName = transaction['payment_type_name'] ?? '';
    final note = transaction['note'];
    final createdDate = transaction['created_date'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isIncome ? Colors.green[200]! : Colors.red[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon and type
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isIncome ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green[600] : Colors.red[600],
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                // Type name and name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isIncome
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${vnd.format(amount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'đ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(height: 1),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.credit_card, size: 16, color: Colors.grey[600]),
                SizedBox(width: 6),
                Text(
                  paymentTypeName,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 6),
                Text(
                  _formatDateTime(createdDate),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            if (note != null && note.toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'Không có phiếu thu chi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chưa có giao dịch nào trong khoảng thời gian này',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }
}
