import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/order/add_storage_order_page.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:nylo_framework/nylo_framework.dart';

final Map<int, String> orderStatus = {
  1: 'Hoàn thành',
  2: 'Chờ xác nhận',
};

final Map<int, Color> orderStatusColor = {
  1: Colors.green,
  2: Colors.orange,
};

class DetailOrderPage extends NyStatefulWidget {
  static const path = '/detail-order';
  final controller = Controller();
  DetailOrderPage({super.key});

  @override
  NyState<DetailOrderPage> createState() => _DetailOrderPageState();
}

class _DetailOrderPageState extends NyState<DetailOrderPage> {
  late Future _future;
  dynamic orderData = {};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _future = fetchDetail();
  }

  Future fetchDetail() async {
    setState(() {
      loading = true;
    });
    try {
      final res = await api<OrderApiService>(
          (request) => request.detailOrder(widget.data()?['id']));
      orderData = res['data'];
      return res['data'];
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  Future deleteOrder(int id) async {
    try {
      await api<OrderApiService>((request) => request.deleteOrder(id));
    } catch (e) {
      CustomToast.showToastError(context, description: getResponseError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColor.get(context).primaryAccent;

    return Scaffold(
      appBar: GradientAppBar(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.white),
            SizedBox(width: 8),
            Text(
              orderData['type'] == 1 ? 'Chi tiết đơn bán' : 'Chi tiết đơn nhập',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(itemBuilder: (BuildContext context) {
            return [
              if (orderData['type'] == 2 && orderData['status_order'] == 2)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(IconsaxPlusLinear.edit_2, color: accent),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(IconsaxPlusLinear.trash, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xoá'),
                  ],
                ),
              ),
            ];
          }, onSelected: (value) {
            switch (value) {
              case 'edit':
                routeTo(AddStorageOrderPage.path, data: {'data': orderData},
                    onPop: (value) {
                  setState(() {
                    _future = fetchDetail();
                  });
                });
                break;
              case 'delete':
                showDeleteConfirm();
                break;
            }
          }),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: accent),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Đã có lỗi xảy ra'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(child: Text('Không có dữ liệu'));
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderCode(),
                  Divider(height: 30),
                  _buildOrderStatus(),
                  Divider(height: 30),
                  _buildOrderInfo(),
                  if (orderData['room'] != null) ...[
                    Divider(height: 30),
                    _buildRoomInfo(),
                  ],
                  if (orderData['note'] != null &&
                      orderData['note'].toString().isNotEmpty) ...[
                    Divider(height: 30),
                    _buildNote(),
                  ],
                  Divider(height: 30),
                  _buildCustomerInfo(),
                  if (orderData['order_detail'] != null &&
                      orderData['order_detail'].isNotEmpty) ...[
                    Divider(height: 30),
                    _buildOrderDetails(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Mã đơn hàng: ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: '#${orderData['id']}',
                  style: TextStyle(
                    color: ThemeColor.get(context).primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void showDeleteConfirm() {
    final pageContext = context;
    showDialog<bool>(
      context: pageContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Xác nhận xoá',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'Bạn có chắc muốn xoá đơn hàng này? Hành động không thể hoàn tác.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Huỷ',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);
                        try {
                          final id = orderData['id'];
                          await deleteOrder(id);
                          CustomToast.showToastSuccess(pageContext,
                              description: 'Xoá đơn thành công');
                          Navigator.of(dialogContext).pop(true);
                          Navigator.of(pageContext).pop(true);
                        } catch (e) {
                          setState(() => isDeleting = false);
                        }
                      },
                child: isDeleting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Xác nhận',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildOrderStatus() {
    final accent = ThemeColor.get(context).primaryAccent;
    final status = orderData['status_order'] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: accent),
            SizedBox(width: 8),
            Expanded(
              child: Text('Trạng thái đơn:', style: TextStyle(fontSize: 15)),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    (orderStatusColor[status] ?? Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: orderStatusColor[status] ?? Colors.grey,
                  width: 1.5,
                ),
              ),
              child: Text(
                orderStatus[status] ?? 'Không xác định',
                style: TextStyle(
                  color: orderStatusColor[status] ?? Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: accent),
            SizedBox(width: 8),
            Expanded(
              child: Text('Ngày tạo:', style: TextStyle(fontSize: 15)),
            ),
            Text(
              formatDate(orderData['created_at']),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        if (orderData['updated_at'] != orderData['created_at']) ...[
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.update, size: 20, color: accent),
              SizedBox(width: 8),
              Expanded(
                child: Text('Cập nhật:', style: TextStyle(fontSize: 15)),
              ),
              Text(
                formatDate(orderData['updated_at']),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOrderInfo() {
    final accent = ThemeColor.get(context).primaryAccent;
    final payment = orderData['payment'] ?? {};
    final paymentType = payment['type'] ?? 1;
    final paymentPrice = payment['price'];
    final totalAmount = orderData['total_amount'] ?? 0;
    final discount = orderData['discount'] ?? 0;
    final discountType = orderData['discount_type'] ?? 1;

    String paymentTypeText = '';
    switch (paymentType) {
      case 1:
        paymentTypeText = 'Tiền mặt';
        break;
      case 2:
        paymentTypeText = 'Chuyển khoản';
        break;
      case 3:
        paymentTypeText = 'Quẹt thẻ';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng tiền & thanh toán',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildInfoRow('Tổng tiền hàng:', vnd.format(totalAmount)),
              if (discount > 0) ...[
                SizedBox(height: 8),
                _buildInfoRow(
                  'Giảm giá:',
                  discountType == 1
                      ? '${discount.toInt()}%'
                      : vnd.format(discount),
                  valueColor: Colors.red,
                ),
              ],
              SizedBox(height: 8),
              Divider(height: 1),
              SizedBox(height: 8),
              _buildInfoRow(
                'Tổng thanh toán:',
                vnd.format(totalAmount -
                    (discountType == 1
                        ? totalAmount * discount / 100
                        : discount)),
                isBold: true,
                valueColor: accent,
              ),
              SizedBox(height: 8),
              _buildInfoRow('Đã thanh toán:', vnd.format(paymentPrice)),
              SizedBox(height: 8),
              _buildInfoRow('Phương thức:', paymentTypeText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomInfo() {
    final room = orderData['room'];
    final area = room?['area'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin bàn',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.table_restaurant,
                size: 20, color: ThemeColor.get(context).primaryAccent),
            SizedBox(width: 8),
            Text('Khu vực: ', style: TextStyle(fontSize: 15)),
            Text(
              '${area?['name'] ?? ''} - ${room?['name'] ?? ''}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Text(
            orderData['note'] ?? '',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    final accent = ThemeColor.get(context).primaryAccent;
    final customer = orderData['customer'];
    final supplier = orderData['supplier'];
    final isOrder = orderData['type'] == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOrder ? 'Thông tin khách hàng' : 'Thông tin nhà cung cấp',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.account_circle, size: 20, color: accent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                isOrder ? 'Khách hàng:' : 'Nhà cung cấp:',
                style: TextStyle(fontSize: 15),
              ),
            ),
            Expanded(
              child: Text(
                (isOrder
                        ? (customer?['name'] ?? 'Khách lẻ')
                        : supplier?['name']) ??
                    'Đại lý',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        if ((isOrder ? (customer?['phone']) : supplier?['phone'] ?? '') !=
            null) ...[
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.phone, size: 20, color: accent),
              SizedBox(width: 8),
              Expanded(
                child: Text('SĐT:', style: TextStyle(fontSize: 15)),
              ),
              Expanded(
                child: Text(
                  (isOrder ? (customer?['phone']) : supplier?['phone']) ?? '',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
        if ((isOrder ? (customer?['address']) : supplier?['address']) !=
            null) ...[
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 20, color: accent),
              SizedBox(width: 8),
              Expanded(
                child: Text('Địa chỉ:', style: TextStyle(fontSize: 15)),
              ),
              Expanded(
                child: Text(
                  (isOrder ? customer!['address'] : supplier!['address']) ?? '',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOrderDetails() {
    final accent = ThemeColor.get(context).primaryAccent;
    final orderDetails = orderData['order_detail'] as List;
    num totalQuantity =
        orderDetails.fold(0, (sum, item) => sum + (item['quantity'] as num));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chi tiết đơn hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Tổng: ${roundQuantity(totalQuantity)} món',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: orderDetails.length,
          itemBuilder: (context, index) {
            return _buildOrderDetailItem(orderDetails[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildOrderDetailItem(dynamic orderDetail, int index) {
    final accent = ThemeColor.get(context).primaryAccent;
    final product = orderDetail['product'] ?? orderDetail['ingredient'];
    final quantity = orderDetail['quantity'];
    final itemPrice = orderDetail['price'] ?? 0;
    final discount = orderDetail['discount'] ?? 0;
    final discountType = orderDetail['discount_type'] ?? 1;
    final note = orderDetail['note'];

    num itemTotal = itemPrice * quantity;
    num discountAmount =
        discountType == 1 ? itemTotal * discount / 100 : discount;
    num finalPrice = itemTotal - discountAmount;

    return Card(
      elevation: 0.5,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product?['image'] != null
                        ? Image.network(
                            product['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 30,
                            ),
                          )
                        : Icon(Icons.image, color: Colors.grey, size: 30),
                  ),
                ),
                SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product?['name'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      if (product?['unit'] != null &&
                          product!['unit'].toString().isNotEmpty)
                        Text(
                          'Đơn vị: ${product['unit']}',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      if (discount > 0)
                        Text(
                          discountType == 1
                              ? 'Giảm giá: ${discount.toInt()}%'
                              : 'Giảm giá: ${vnd.format(discount)}',
                          style: TextStyle(fontSize: 13, color: Colors.red),
                        ),
                    ],
                  ),
                ),
                // Quantity & Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SL: ${roundQuantity(quantity)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Đơn giá: ${vnd.format(itemPrice)}',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'T.Tiền: ${vnd.format(finalPrice)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (note != null && note.toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.orange[700]),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ghi chú: $note',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[900]),
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
}
