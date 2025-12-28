import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/customer.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/order/select_multi_product_page.dart';
import 'package:flutter_app/resources/widgets/select_customer.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditOrderPage extends NyStatefulWidget {
  static const path = '/edit-order';
  final controller = Controller();
  EditOrderPage({super.key});

  @override
  NyState<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends NyState<EditOrderPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _customerSelectKey = GlobalKey<DropdownSearchState<Customer>>();

  List<Product> _selectedProducts = [];
  bool _isSubmitting = false;

  String get roomName => widget.data()?['room_name'] ?? '';
  String get areaName => widget.data()?['area_name'] ?? '';
  int? get roomId => widget.data()?['room_id'];
  String? get roomType => widget.data()?['room_type'];

  @override
  void initState() {
    super.initState();
    _initializeOrderData();
  }

  void _initializeOrderData() {
    final selectedProducts =
        widget.data()?['selected_products'] as List<Product>? ?? [];
    _selectedProducts = List<Product>.from(selectedProducts);
    setState(() {});
  }

  void _updateQuantity(Product product, int delta) {
    setState(() {
      product.quantity += delta;
      if (product.quantity <= 0) {
        _selectedProducts.removeWhere((p) => p.id == product.id);
      }
    });
  }

  void _removeItem(Product product) {
    setState(() {
      _selectedProducts.removeWhere((p) => p.id == product.id);
    });
  }

  Future<void> _selectMoreProducts() async {
    final result = await Navigator.pushNamed(
      context,
      SelectMultiProductPage.path,
      arguments: {
        'room_name': roomName,
        'area_name': areaName,
        'room_id': roomId,
        'room_type': roomType,
      },
    );

    if (result != null && result is List<Product>) {
      setState(() {
        for (var newProduct in result) {
          final existingIndex =
              _selectedProducts.indexWhere((p) => p.id == newProduct.id);
          if (existingIndex != -1) {
            // Cộng dồn số lượng nếu đã có
            _selectedProducts[existingIndex].quantity += newProduct.quantity;
          } else {
            // Thêm mới
            _selectedProducts.add(newProduct);
          }
        }
      });
    }
  }

  Future<void> _submitOrder({required bool isPayment}) async {
    if (!_formKey.currentState!.saveAndValidate()) {
      CustomToast.showToastWarning(context,
          description: "Vui lòng điền đầy đủ thông tin");
      return;
    }

    if (_selectedProducts.isEmpty) {
      CustomToast.showToastWarning(context,
          description: "Vui lòng chọn ít nhất 1 sản phẩm");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formData = _formKey.currentState!.value;

      // Build order_detail array
      List<Map<String, dynamic>> orderDetail = [];
      for (var product in _selectedProducts) {
        final priceKey = 'price_${product.id}';
        final discountKey = 'discount_${product.id}';
        final discountTypeKey = 'discount_type_${product.id}';
        final noteKey = 'note_${product.id}';

        orderDetail.add({
          'product_id': product.id,
          'quantity': product.quantity,
          'user_price': formData[priceKey] ?? product.retailCost ?? 0,
          if (formData[discountKey] != null && formData[discountKey] > 0)
            'discount': formData[discountKey],
          if (formData[discountTypeKey] != null)
            'discount_type': formData[discountTypeKey],
          if (formData[noteKey] != null &&
              formData[noteKey].toString().isNotEmpty)
            'note': formData[noteKey],
        });
      }

      // Build payload
      Map<String, dynamic> payload = {
        'type': 1, // Đơn bán
        'room_id': roomId,
        // Thanh toán → bàn free, Tạo đơn → bàn using
        'room_type': isPayment ? 'free' : 'using',
        if (formData['customer_id'] != null)
          'customer_id': formData['customer_id'],
        'order_detail': orderDetail,
        'payment': {
          'type': formData['payment_type'] ?? 1,
          'price': formData['payment_price'] ?? 0,
        },
        if (formData['order_note'] != null &&
            formData['order_note'].toString().isNotEmpty)
          'note': formData['order_note'],
        if (formData['order_discount'] != null &&
            formData['order_discount'] > 0)
          'discount': formData['order_discount'],
        if (formData['order_discount_type'] != null)
          'discount_type': formData['order_discount_type'],
        // Thanh toán → status = 2, Tạo đơn → status = 1
        'status_order': isPayment ? 2 : 1,
      };

      log('Payload: ${payload.toString()}');
      await api<OrderApiService>((request) => request.createOrder(payload));

      CustomToast.showToastSuccess(context,
          description:
              isPayment ? "Thanh toán thành công" : "Tạo đơn hàng thành công");
      Navigator.pop(context, true);
    } catch (error) {
      CustomToast.showToastError(context, description: getResponseError(error));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: ThemeColor.get(context).primaryAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo đơn bán - $areaName - $roomName',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Selection
                    _buildSectionCard(
                      title: 'Thông tin khách hàng',
                      child: CustomerSelect(
                        selectKey: _customerSelectKey,
                        labelText: 'Chọn khách hàng',
                        hintText: 'Tìm kiếm khách hàng...',
                        onSelect: (customer) {
                          _formKey.currentState?.fields['customer_id']
                              ?.didChange(customer?.id);
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Product List
                    _buildSectionCard(
                      title: 'Danh sách sản phẩm',
                      child: Column(
                        children: [
                          if (_selectedProducts.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.h),
                                child: Text(
                                  'Chưa có sản phẩm nào',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 14.sp),
                                ),
                              ),
                            )
                          else
                            ..._selectedProducts.map((product) {
                              return _buildProductItemCard(product);
                            }).toList(),
                          SizedBox(height: 10.h),
                          ElevatedButton.icon(
                            onPressed: _selectMoreProducts,
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text('Chọn thêm sản phẩm',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  ThemeColor.get(context).primaryAccent,
                              minimumSize: Size(double.infinity, 45.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Order Discount & Note
                    _buildSectionCard(
                      title: 'Giảm giá & Ghi chú đơn hàng',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: FormBuilderTextField(
                                  name: 'order_discount',
                                  decoration: InputDecoration(
                                    labelText: 'Giảm giá',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 12.h),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.numeric(),
                                    FormBuilderValidators.min(0),
                                  ]),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: FormBuilderDropdown<int>(
                                  name: 'order_discount_type',
                                  decoration: InputDecoration(
                                    labelText: 'Loại',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 12.h),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                        value: 1, child: Text('VNĐ')),
                                    DropdownMenuItem(
                                        value: 2, child: Text('%')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          FormBuilderTextField(
                            name: 'order_note',
                            decoration: InputDecoration(
                              labelText: 'Ghi chú',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 12.h),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Payment
                    _buildSectionCard(
                      title: 'Thanh toán',
                      child: Column(
                        children: [
                          FormBuilderDropdown<int>(
                            name: 'payment_type',
                            decoration: InputDecoration(
                              labelText: 'Phương thức',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 12.h),
                            ),
                            initialValue: 1,
                            validator: FormBuilderValidators.required(),
                            items: [
                              DropdownMenuItem(
                                  value: 1, child: Text('Tiền mặt')),
                              DropdownMenuItem(
                                  value: 2, child: Text('Chuyển khoản')),
                              DropdownMenuItem(
                                  value: 3, child: Text('Quẹt thẻ')),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          FormBuilderTextField(
                            name: 'payment_price',
                            decoration: InputDecoration(
                              labelText: 'Số tiền thanh toán',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 12.h),
                              suffixText: 'VNĐ',
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: '0',
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.numeric(),
                              FormBuilderValidators.min(0),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Button Tạo đơn (status_order = 1, room_type = using)
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitOrder(isPayment: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart, color: Colors.white),
                            SizedBox(width: 8.w),
                            Text(
                              'Tạo đơn',
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              // Button Thanh toán (status_order = 2, room_type = free)
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitOrder(isPayment: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, color: Colors.white),
                            SizedBox(width: 8.w),
                            Text(
                              'Thanh toán',
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProductItemCard(Product product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Image
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.image, color: Colors.grey[500]),
                          ),
                        )
                      : Icon(Icons.image, color: Colors.grey[500]),
                ),
                SizedBox(width: 12.w),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? '',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        vnd.format(product.retailCost),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Quantity Controls
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      color: Colors.grey[700],
                      onPressed: () => _updateQuantity(product, -1),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${product.quantity.toInt()}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      color: ThemeColor.get(context).primaryAccent,
                      onPressed: () => _updateQuantity(product, 1),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(IconsaxPlusLinear.trash,
                      color: Colors.red, size: 20.w),
                  onPressed: () => _removeItem(product),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Price
            FormBuilderTextField(
              name: 'price_${product.id}',
              decoration: InputDecoration(
                labelText: 'Giá bán',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                suffixText: 'VNĐ',
              ),
              initialValue: product.retailCost?.toString() ?? '0',
              keyboardType: TextInputType.number,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.numeric(),
                FormBuilderValidators.min(0),
              ]),
            ),
            SizedBox(height: 10.h),
            // Discount
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FormBuilderTextField(
                    name: 'discount_${product.id}',
                    decoration: InputDecoration(
                      labelText: 'Giảm giá',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 10.h),
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.min(0),
                    ]),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: FormBuilderDropdown<int>(
                    name: 'discount_type_${product.id}',
                    decoration: InputDecoration(
                      labelText: 'Loại',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 10.h),
                    ),
                    items: [
                      DropdownMenuItem(value: 1, child: Text('VNĐ')),
                      DropdownMenuItem(value: 2, child: Text('%')),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Note
            FormBuilderTextField(
              name: 'note_${product.id}',
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
