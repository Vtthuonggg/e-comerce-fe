// File: lib/resources/pages/order/edit_order_page.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/customer.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/order/select_multi_product_page.dart';
import 'package:flutter_app/resources/pages/table/table_item.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class EditOrderPage extends NyStatefulWidget {
  static const path = '/edit-order';
  final controller = Controller();
  EditOrderPage({super.key});

  @override
  NyState<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends NyState<EditOrderPage> {
  final discountController = TextEditingController();
  final paidController = TextEditingController();
  final _formKey = GlobalKey<FormBuilderState>();

  List<Product> selectedItems = [];
  bool _isLoading = false;
  DiscountType _discountType = DiscountType.percent;
  Customer? selectedCustomer;
  int selectPaymentType = 1;

  String get roomName => widget.data()?['room_name'] ?? '';
  String get areaName => widget.data()?['area_name'] ?? '';
  int? get roomId => widget.data()?['room_id'];
  TableStatus get currentRoomType =>
      TableStatusExtension.fromValue(widget.data()?['room_type'] ?? 'free');

  @override
  void initState() {
    super.initState();
    _initializeOrderData();
  }

  @override
  void dispose() {
    discountController.dispose();
    paidController.dispose();
    for (var item in selectedItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _initializeOrderData() {
    final selectedProducts =
        widget.data()?['selected_products'] as List<Product>? ?? [];
    selectedItems = List<Product>.from(selectedProducts);
    updatePaid();
  }

  void addItem(Product item) {
    var index = selectedItems.indexWhere((element) => element.id == item.id);
    if (index == -1) {
      item.isSelected = true;
      item.quantity = 1;
      item.txtQuantity.text = '1';
      item.txtPrice.text = vnd.format(item.retailCost ?? 0);
      item.txtDiscount.text = '0';
      item.discount = 0;
      selectedItems.add(item);
    } else {
      selectedItems[index].quantity++;
      selectedItems[index].txtQuantity.text =
          roundQuantity(selectedItems[index].quantity);
    }
    resetItemPrice();
    updatePaid();
    setState(() {});
  }

  void removeItem(Product item) {
    item.isSelected = false;
    item.quantity = 1;
    item.discount = 0;
    item.discountType = DiscountType.percent;
    item.txtQuantity.text = '1';
    item.txtPrice.text = vnd.format(0);
    item.txtDiscount.text = '0';
    setState(() {
      selectedItems.removeWhere((element) => element.id == item.id);
      resetItemPrice();
    });
    updatePaid();
  }

  void resetItemPrice() {
    for (var item in selectedItems) {
      if (!item.isManuallyEdited) {
        num price = item.retailCost ?? 0;
        item.txtPrice.text = vnd.format(price);
      }
    }
  }

  void updatePaid() {
    num finalPrice = getFinalPrice();
    paidController.text = vnd.format(finalPrice);
    setState(() {});
  }

  num getTotalPrice() {
    num total = 0;
    for (var item in selectedItems) {
      num price = stringToInt(item.txtPrice.text) ?? item.retailCost ?? 0;
      num quantity = item.quantity;
      num itemTotal = price * quantity;

      num discountVal = item.discount ?? 0;
      num discountPrice = item.discountType == DiscountType.percent
          ? itemTotal * discountVal / 100
          : discountVal;

      total += (itemTotal - discountPrice);
    }
    return total;
  }

  num getTotalQty() {
    num total = 0;
    for (var item in selectedItems) {
      total += item.quantity;
    }
    return total;
  }

  num getFinalPrice() {
    num total = getTotalPrice();

    // Apply order discount
    num orderDiscount = stringToInt(discountController.text) ?? 0;
    if (orderDiscount > 0) {
      if (_discountType == DiscountType.percent) {
        total = total - (total * orderDiscount / 100);
      } else {
        total = total - orderDiscount;
      }
    }

    return total < 0 ? 0 : total;
  }

  num getPaid() {
    return stringToInt(_formKey.currentState?.value['paid'] ?? '0') ?? 0;
  }

  num getDebt() {
    num finalPrice = getFinalPrice();
    num paid = getPaid();
    return paid - finalPrice;
  }

  Future<void> _selectMoreProducts() async {
    final result = await Navigator.pushNamed(
      context,
      SelectMultiProductPage.path,
      arguments: {
        'room_name': roomName,
        'area_name': areaName,
        'room_id': roomId,
        'room_type': currentRoomType.toValue(),
        'items': selectedItems,
      },
    );

    if (result != null && result is List<Product>) {
      setState(() {
        for (var newProduct in result) {
          addItem(newProduct);
        }
      });
    }
  }

  Future submit(TableStatus roomType, {bool isPay = false}) async {
    if (!_formKey.currentState!.saveAndValidate()) {
      CustomToast.showToastWarning(context,
          description: "Vui lòng điền đầy đủ thông tin");
      return;
    }

    if (selectedItems.isEmpty) {
      CustomToast.showToastWarning(context,
          description: "Vui lòng chọn ít nhất 1 sản phẩm");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build order_detail
      List<Map<String, dynamic>> orderDetail = [];
      for (var product in selectedItems) {
        num price =
            stringToInt(product.txtPrice.text) ?? product.retailCost ?? 0;
        num discount = product.discount ?? 0;

        orderDetail.add({
          'product_id': product.id,
          'quantity': product.quantity,
          'retail_cost': price,
          if (discount > 0) 'discount': discount,
          if (discount > 0)
            'discount_type': product.discountType.getValueRequest(),
          if (product.note != null && product.note!.isNotEmpty)
            'note': product.note,
        });
      }

      // Build payload
      Map<String, dynamic> payload = {
        'type': 1,
        'room_id': roomId,
        'room_type': isPay ? TableStatus.free.toValue() : roomType.toValue(),
        if (selectedCustomer != null) 'customer_id': selectedCustomer!.id,
        'order_detail': orderDetail,
        'payment': {
          'type': selectPaymentType,
          'price': stringToInt(paidController.text) ?? 0,
        },
        if (_formKey.currentState?.value['order_note'] != null &&
            _formKey.currentState!.value['order_note'].toString().isNotEmpty)
          'note': _formKey.currentState!.value['order_note'],
        if (stringToInt(discountController.text) != null &&
            stringToInt(discountController.text)! > 0)
          'discount': stringToInt(discountController.text),
        if (stringToInt(discountController.text) != null &&
            stringToInt(discountController.text)! > 0)
          'discount_type': _discountType.getValueRequest(),
        'status_order': isPay ? 4 : 2,
      };

      log('Payload: ${payload.toString()}');
      await api<OrderApiService>((request) => request.createOrder(payload));

      CustomToast.showToastSuccess(context,
          description:
              isPay ? "Thanh toán thành công" : "Tạo đơn hàng thành công");
      Navigator.pop(context, true);
    } catch (error) {
      CustomToast.showToastError(context, description: getResponseError(error));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ThemeColor.get(context).primaryAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đặt bàn',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _selectMoreProducts,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildBreadCrumb(),
                      FormBuilder(
                        key: _formKey,
                        onChanged: () {
                          _formKey.currentState!.save();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildCustomerDetail(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 0.0, horizontal: 6.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey[200] ?? Colors.grey),
                                  left: BorderSide(
                                      color: Colors.grey[200] ?? Colors.grey),
                                  right: BorderSide(
                                      color: Colors.grey[200] ?? Colors.grey),
                                  top: BorderSide(
                                      color: Colors.grey[200] ?? Colors.grey),
                                ),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10.0),
                                    topRight: Radius.circular(10.0)),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Tổng SL món: ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600]),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: '${roundQuantity(getTotalQty())}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            buildListItem(),
                            buildSummary(),
                            Divider(),
                            buildNote(),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              buildMainActionButton(context),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBreadCrumb() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.table_restaurant,
              size: 20, color: ThemeColor.get(context).primaryAccent),
          SizedBox(width: 8),
          Text(
            '$areaName - $roomName',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget buildCustomerDetail() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
              SizedBox(width: 8),
              Text(
                'Thông tin khách hàng',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
            ],
          ),
          SizedBox(height: 12),
          InkWell(
            onTap: () {
              // TODO: Show customer selection dialog
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCustomer?.name ?? 'Chọn khách hàng',
                    style: TextStyle(
                        fontSize: 14,
                        color: selectedCustomer != null
                            ? Colors.black
                            : Colors.grey[600]),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListItem() {
    return Column(
      children: selectedItems.map((item) {
        return buildItem(item, selectedItems.indexOf(item));
      }).toList(),
    );
  }

  Widget buildItem(Product item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.image, color: Colors.grey, size: 30),
                        ),
                      )
                    : Icon(Icons.image, color: Colors.grey, size: 30),
              ),
              SizedBox(width: 12),
              // Info
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name ?? '',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          vnd.format(item.retailCost ?? 0),
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(IconsaxPlusLinear.trash,
                          color: ThemeColor.get(context).primaryAccent,
                          size: 20),
                      onPressed: () {
                        removeItem(item);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Quantity Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số lượng',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 18),
                      onPressed: () {
                        if (item.quantity > 1) {
                          setState(() {
                            item.quantity--;
                            item.txtQuantity.text =
                                roundQuantity(item.quantity);
                            updatePaid();
                          });
                        }
                      },
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                    Container(
                      width: 60,
                      child: FormBuilderTextField(
                        name: '${item.id}.quantity',
                        controller: item.txtQuantity,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          num newQuantity = stringToDouble(val) ?? 0;
                          item.quantity = newQuantity;
                          updatePaid();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() {
                          item.quantity++;
                          item.txtQuantity.text = roundQuantity(item.quantity);
                          updatePaid();
                        });
                      },
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Price
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giá bán',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    FormBuilderTextField(
                      name: '${item.id}.price',
                      controller: item.txtPrice,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixText: 'đ',
                        isDense: true,
                      ),
                      onChanged: (_) {
                        item.isManuallyEdited = true;
                        updatePaid();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Discount
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giảm giá',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    FormBuilderTextField(
                      name: '${item.id}.discount',
                      controller: item.txtDiscount,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          item.discount = num.tryParse(val ?? '0') ?? 0;
                          updatePaid();
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loại',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    DropdownButtonFormField<DiscountType>(
                      value: item.discountType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: DiscountType.price, child: Text('đ')),
                        DropdownMenuItem(
                            value: DiscountType.percent, child: Text('%')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            item.discountType = val;
                            updatePaid();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Note
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ghi chú',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              FormBuilderTextField(
                name: '${item.id}.note',
                style: TextStyle(fontSize: 13),
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                  hintText: 'Nhập ghi chú...',
                ),
                maxLines: 1,
                onChanged: (val) {
                  item.note = val;
                },
              ),
            ],
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
                'Tổng tiền: ${vnd.format((stringToInt(item.txtPrice.text) ?? 0) * item.quantity - (item.discountType == DiscountType.percent ? ((stringToInt(item.txtPrice.text) ?? 0) * item.quantity * (item.discount ?? 0) / 100) : (item.discount ?? 0)))}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Widget buildSummary() {
    return Column(
      children: [
        SizedBox(height: 12),
        buildOrderDiscount(),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tổng tiền T.Toán',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 40,
              width: 180,
              child: FormBuilderTextField(
                name: 'total_price',
                enabled: false,
                controller: TextEditingController(
                    text: vnd.format(roundMoney(getFinalPrice()))),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '',
                  suffixText: '',
                ),
              ),
            )
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Khách T.Toán', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 45,
                    width: 180,
                    child: FormBuilderTextField(
                      keyboardType: TextInputType.number,
                      name: 'paid',
                      controller: paidController,
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                      onChanged: (value) {
                        setState(() {});
                      },
                      onTap: () {
                        _formKey.currentState!.patchValue({'paid': ''});
                      },
                      inputFormatters: [
                        CurrencyTextInputFormatter(
                          locale: 'vi',
                          symbol: '',
                        )
                      ],
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        suffixText: 'đ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        if (getDebt() != 0)
          Column(
            children: [
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(getDebt() > 0 ? 'Tiền thừa' : 'Còn nợ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 40,
                    width: 180,
                    child: FormBuilderTextField(
                      name: 'debt',
                      enabled: false,
                      controller: TextEditingController(
                          text: vnd.format(getDebt().abs())),
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        hintText: '',
                        suffixText: '',
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hình thức T.Toán',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 180,
              height: 40,
              child: FormBuilderDropdown<int>(
                name: 'payment_type',
                initialValue: selectPaymentType,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: ThemeColor.get(context).primaryAccent,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text('Tiền mặt')),
                  DropdownMenuItem(value: 2, child: Text('Chuyển khoản')),
                  DropdownMenuItem(value: 3, child: Text('Quẹt thẻ')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectPaymentType = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildOrderDiscount() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Giảm giá đơn hàng',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              FormBuilderTextField(
                name: 'order_discount',
                controller: discountController,
                keyboardType: TextInputType.number,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                style: TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                  hintText: '0',
                ),
                onChanged: (val) {
                  updatePaid();
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loại',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              DropdownButtonFormField<DiscountType>(
                value: _discountType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: DiscountType.price, child: Text('đ')),
                  DropdownMenuItem(
                      value: DiscountType.percent, child: Text('%')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _discountType = val;
                      updatePaid();
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ghi chú đơn hàng',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        FormBuilderTextField(
          name: 'order_note',
          onTapOutside: (event) => FocusScope.of(context).unfocus(),
          style: TextStyle(fontSize: 13),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: 'Nhập ghi chú cho đơn hàng...',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget buildMainActionButton(BuildContext context) {
    if (currentRoomType == TableStatus.using) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.green,
                minimumSize: Size(80, 40),
              ),
              onPressed: () => submit(currentRoomType),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Cập nhật', style: TextStyle(color: Colors.white)),
                      ],
                    ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(80, 40),
                backgroundColor: Colors.blue,
              ),
              onPressed: () => submit(TableStatus.free, isPay: true),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_money, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Thanh toán',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      );
    } else if (currentRoomType == TableStatus.preOrder) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.green,
                minimumSize: Size(80, 40),
              ),
              onPressed: () => submit(currentRoomType),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Cập nhật', style: TextStyle(color: Colors.white)),
                      ],
                    ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.blue,
                minimumSize: Size(80, 40),
              ),
              onPressed: () => submit(TableStatus.using),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Tạo đơn', style: TextStyle(color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.green,
              minimumSize: Size(80, 40),
            ),
            onPressed: () => submit(TableStatus.using),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Tạo đơn', style: TextStyle(color: Colors.white)),
                    ],
                  ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size(80, 40),
              backgroundColor: Colors.blue,
            ),
            onPressed: () => submit(TableStatus.free, isPay: true),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Thanh toán', style: TextStyle(color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
