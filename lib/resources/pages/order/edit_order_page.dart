import 'dart:async';
import 'dart:developer';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/customer.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/app/utils/socket_manager.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/table/table_item.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:flutter_app/resources/widgets/order_product_item.dart';
import 'package:flutter_app/resources/widgets/select_multi_product.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class EditOrderPage extends NyStatefulWidget {
  static const path = '/edit-order';
  final controller = Controller();
  EditOrderPage({super.key});

  @override
  NyState<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends NyState<EditOrderPage> {
  String get roomName => widget.data()?['room_name'] ?? '';
  String get areaName => widget.data()?['area_name'] ?? '';
  int? get roomId => widget.data()?['room_id'];
  TableStatus get currentRoomType =>
      TableStatusExtension.fromValue(widget.data()?['room_type'] ?? 'free');
  bool get isEdit => widget.data()?['order_id'] != null;

  final discountController = TextEditingController();
  final paidController = TextEditingController();
  final _formKey = GlobalKey<FormBuilderState>();
  final _selectProductMultiKey = GlobalKey<DropdownSearchState<Product>>();

  List<Product> selectedItems = [];
  bool _isLoading = false;
  bool _fetching = false;
  DiscountType _discountType = DiscountType.percent;
  Customer? selectedCustomer;
  int selectPaymentType = 1;

  SocketManager _socketManager = SocketManager();

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _patchEditData();
      });
    }
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

  void _patchEditData() async {
    setState(() {
      _fetching = true;
    });

    try {
      int orderId = widget.data()?['order_id'];
      var response =
          await api<OrderApiService>((request) => request.detailOrder(orderId));

      // Lấy data từ response
      var orderData = response['data'];

      // Patch selected products
      List<Product> products = [];
      if (orderData['order_detail'] != null) {
        for (var item in orderData['order_detail']) {
          // Check null safety cho product
          if (item['product'] == null) continue;

          Product product = Product.fromJson(item['product']);
          product.isSelected = true;
          product.quantity = item['quantity'] ?? 1;
          product.txtQuantity.text = roundQuantity(product.quantity);
          if (item['topping'] != null && item['topping'] is List) {
            List<Product> productToppings = [];
            for (var toppingData in item['topping']) {
              if (toppingData['product'] == null) continue;

              Product topping = Product.fromJson(toppingData['product']);
              topping.quantity = toppingData['quantity'] ?? 1;
              topping.txtQuantity.text = roundQuantity(topping.quantity);

              productToppings.add(topping);
            }
            product.toppings = productToppings;
          }
          // Patch price
          num price = item['price'] ?? product.retailCost ?? 0;
          product.txtPrice.text = vnd.format(roundMoney(price));

          // Patch discount
          if (item['discount'] != null && item['discount'] > 0) {
            product.discount = item['discount'];
            product.discountType =
                DiscountType.fromValueRequest(item['discount_type']);
            product.txtDiscount.text =
                product.discountType == DiscountType.percent
                    ? (product.discount ?? 0).toStringAsFixed(2)
                    : vnd.format(roundMoney(product.discount ?? 0));
          } else {
            product.discount = 0;
            product.discountType = DiscountType.percent;
            product.txtDiscount.text = '0';
          }

          // Patch note
          if (item['note'] != null && item['note'].toString().isNotEmpty) {
            product.note = item['note'];
            product.txtNote.text = item['note'];
          }

          products.add(product);
        }
      }

      setState(() {
        selectedItems = products;

        // Patch order discount
        if (orderData['discount'] != null && orderData['discount'] > 0) {
          _discountType =
              DiscountType.fromValueRequest(orderData['discount_type']);
          discountController.text = _discountType == DiscountType.percent
              ? (orderData['discount'] ?? 0).toStringAsFixed(2)
              : vnd.format(roundMoney(orderData['discount'] ?? 0));
        } else {
          _discountType = DiscountType.percent;
          discountController.text = '0';
        }

        // Patch customer
        selectedCustomer = orderData['customer'] != null
            ? Customer.fromJson(orderData['customer'])
            : null;

        // Patch payment info
        if (orderData['payment'] != null) {
          selectPaymentType = orderData['payment']['type'] ?? 1;
          // Note: paidController sẽ được update trong updatePaid()
        }

        // Patch order note vào form
        if (orderData['note'] != null &&
            orderData['note'].toString().isNotEmpty) {
          _formKey.currentState?.patchValue({
            'order_note': orderData['note'],
          });
        }
      });

      updatePaid();
    } catch (error) {
      log('Error in _patchEditData: $error');
      CustomToast.showToastError(context, description: getResponseError(error));
    } finally {
      setState(() {
        _fetching = false;
      });
    }
  }

  void removeItem(Product item) {
    setState(() {
      item.isSelected = false;
      item.quantity = 1;
      item.discount = 0;
      item.discountType = DiscountType.percent;
      selectedItems.removeWhere((element) => element.id == item.id);
    });
    updatePaid();
  }

  void updatePaid() {
    num finalPrice = getFinalPrice();
    paidController.text = vnd.format(roundMoney(finalPrice));
    if (mounted) {
      setState(() {});
    }
  }

  num getTotalPrice() {
    num total = 0;
    for (var item in selectedItems) {
      total += getPrice(item);
    }
    return total;
  }

  num getPrice(Product item) {
    num baseCost = stringToInt(item.txtPrice.text) ?? item.retailCost ?? 0;
    num quantity = item.quantity;
    num price = baseCost;
    num itemTotal = price * quantity;

    // Apply discount
    num discountVal = (item.discount ?? 0);
    num discountPrice = item.discountType == DiscountType.percent
        ? itemTotal * discountVal / 100
        : discountVal;

    return itemTotal - discountPrice;
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
    num discountVal = _discountType == DiscountType.percent
        ? stringToDouble(discountController.text) ?? 0
        : stringToInt(discountController.text) ?? 0;

    num discountPrice = _discountType == DiscountType.percent
        ? total * discountVal / 100
        : discountVal;

    total = total - discountPrice;
    return total < 0 ? 0 : total;
  }

  num getPaid() {
    return stringToInt(paidController.text) ?? 0;
  }

  num getDebt() {
    num finalPrice = getFinalPrice();
    num paid = getPaid();
    return paid - finalPrice;
  }

  void checkDiscountOrder() {
    if (_isLoading) return;
    num discount = _discountType == DiscountType.price
        ? stringToInt(discountController.text) ?? 0
        : stringToDouble(discountController.text) ?? 0;

    if (_discountType == DiscountType.price && discount > getTotalPrice()) {
      CustomToast.showToastError(context,
          description: "Chiết khấu không được lớn hơn tổng tiền");
      Future.delayed(Duration(milliseconds: 100), () {
        String currentText = discountController.text;
        if (currentText.isNotEmpty) {
          discountController.text = vnd.format(getTotalPrice());
        }
      });
      return;
    }

    if (_discountType == DiscountType.percent && discount > 100) {
      Future.delayed(Duration(milliseconds: 100), () {
        discountController.text = '100';
      });
      return;
    }

    if (mounted) {
      setState(() {});
      updatePaid();
    }
  }

  void checkDiscountItem(Product item) {
    if (_isLoading) return;

    num currentPrice = stringToInt(item.txtPrice.text) ?? 0;
    num discount = item.discount ?? 0;

    if (item.discountType == DiscountType.price &&
        discount > currentPrice * item.quantity) {
      Future.delayed(Duration(milliseconds: 100), () {
        item.txtDiscount.text = vnd.format(currentPrice * item.quantity);
      });
      return;
    }

    if (item.discountType == DiscountType.percent && discount > 100) {
      CustomToast.showToastError(context,
          description: "Chiết khấu không được lớn hơn 100%");
      Future.delayed(Duration(milliseconds: 100), () {
        item.txtDiscount.text = '100';
      });
      return;
    }

    if (mounted) {
      setState(() {});
      updatePaid();
    }
  }

  Future submit(TableStatus roomType, {bool isPay = false}) async {
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
          'price': price,
          if (discount > 0) 'discount': discount,
          if (discount > 0)
            'discount_type': product.discountType.getValueRequest(),
          if (product.note != null && product.note!.isNotEmpty)
            'note': product.note,
          if (product.toppings?.isNotEmpty == true)
            'topping': product.toppings!.map((topping) {
              return {
                'product_id': topping.id,
                'quantity': topping.quantity,
              };
            }).toList(),
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
          'discount': _discountType == DiscountType.percent
              ? stringToDouble(discountController.text)
              : stringToInt(discountController.text),
        if (stringToInt(discountController.text) != null &&
            stringToInt(discountController.text)! > 0)
          'discount_type': _discountType.getValueRequest(),
        'status_order': isPay ? 1 : 2,
      };
      if (isEdit) {
        await api<OrderApiService>((request) =>
            request.updateOrder(widget.data()?['order_id'], payload));
      } else {
        await api<OrderApiService>((request) => request.createOrder(payload));
      }
      if (isPay) {
        _socketManager.sendEvent('user', {'user_id': Auth.user<User>()?.id});
      }
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
          'Tạo đơn',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: _fetching
              ? Center(
                  child: AppLoading(),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: FormBuilder(
                          key: _formKey,
                          onChanged: () {
                            _formKey.currentState!.save();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 16),
                              buildBreadCrumb(),
                              SizedBox(height: 16),

                              // Product selection
                              ProductMultiSelect(
                                multiKey: _selectProductMultiKey,
                                selectedItems: selectedItems,
                                isShowList: false,
                                onSelect: (items) {
                                  setState(() {
                                    selectedItems = items ?? [];
                                    updatePaid();
                                  });
                                },
                              ),

                              SizedBox(height: 16),

                              // Display selected products
                              if (selectedItems.isNotEmpty) ...[
                                ...selectedItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return OrderProductItem(
                                    key: ValueKey(item.id),
                                    item: item,
                                    index: index,
                                    updatePaid: () => updatePaid(),
                                    removeItem: (product) {
                                      removeItem(product);
                                    },
                                    onMinusQuantity: () {
                                      if (item.quantity >= 1) {
                                        String newQuantityStr =
                                            (item.quantity - 1)
                                                .toStringAsFixed(3);
                                        num newQuantity =
                                            stringToDouble(newQuantityStr) ?? 0;
                                        if (newQuantity ==
                                            newQuantity.floor()) {
                                          item.quantity = newQuantity.toInt();
                                        } else {
                                          item.quantity =
                                              newQuantity.toDouble();
                                        }
                                        item.txtQuantity.text =
                                            roundQuantity(item.quantity);
                                        updatePaid();
                                      }
                                    },
                                    getPrice: () => getPrice(item),
                                    onChangeQuantity: (value) {
                                      setState(() {
                                        item.quantity =
                                            stringToDouble(value) ?? 0;
                                      });
                                      updatePaid();
                                    },
                                    onIncreaseQuantity: () {
                                      String newQuantityStr =
                                          (item.quantity + 1)
                                              .toStringAsFixed(3);
                                      num newQuantity =
                                          stringToDouble(newQuantityStr) ?? 0;
                                      if (newQuantity == newQuantity.floor()) {
                                        item.quantity = newQuantity.toInt();
                                      } else {
                                        item.quantity = newQuantity;
                                      }
                                      item.txtQuantity.text =
                                          roundQuantity(item.quantity);
                                      updatePaid();
                                    },
                                    onChangePrice: (value) {
                                      updatePaid();
                                      setState(() {});
                                    },
                                    onChangeDiscount: (value) {
                                      item.discount = item.discountType ==
                                              DiscountType.percent
                                          ? (stringToDouble(value) ?? 0)
                                          : (stringToInt(value) ?? 0);
                                      checkDiscountItem(item);
                                      checkDiscountOrder();
                                      updatePaid();
                                      setState(() {});
                                    },
                                    onChangeDiscountType: (value) {
                                      setState(() {
                                        item.discountType = value;
                                      });
                                      updatePaid();
                                    },
                                  );
                                }),
                              ],

                              SizedBox(height: 16),
                              Divider(),
                              buildSummary(),
                              Divider(),
                              SizedBox(height: 16),
                              buildNote(),
                              SizedBox(height: 20),
                            ],
                          ),
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
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
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

  Widget buildSummary() {
    return Column(
      children: [
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
                  suffixText: 'đ',
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
            SizedBox(
              height: 40,
              width: 180,
              child: FormBuilderTextField(
                keyboardType: TextInputType.number,
                name: 'paid',
                controller: paidController,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
                onChanged: (value) {
                  setState(() {});
                },
                onTap: () {
                  paidController.clear();
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
        if (getDebt() != 0) ...[
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
                  controller:
                      TextEditingController(text: vnd.format(getDebt().abs())),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    suffixText: 'đ',
                  ),
                ),
              )
            ],
          ),
        ],
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Chiết khấu', style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(),
        SizedBox(
          height: 40,
          width: 180,
          child: FormBuilderTextField(
            controller: discountController,
            name: 'discount',
            onChanged: (value) {
              setState(() {
                checkDiscountOrder();
              });
            },
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
            keyboardType:
                TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: _discountType == DiscountType.percent
                ? [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ]
                : [
                    CurrencyTextInputFormatter(
                      locale: 'vi',
                      symbol: '',
                    ),
                    FilteringTextInputFormatter.deny(
                      RegExp(r'-'),
                    ),
                  ],
            decoration: InputDecoration(
              suffixIcon: SizedBox(
                  child: CupertinoSlidingSegmentedControl<DiscountType>(
                thumbColor: ThemeColor.get(context).primaryAccent,
                onValueChanged: (DiscountType? value) {
                  if (value == DiscountType.percent) {
                    double discount = stringToDouble(
                            _formKey.currentState?.value['discount']) ??
                        0;
                    if (discount > 100) {
                      discount = 100;
                    }
                    _formKey.currentState?.patchValue({
                      'discount':
                          discount == 0.0 ? '' : discount.toStringAsFixed(0),
                    });
                  } else {
                    _formKey.currentState?.patchValue({
                      'discount': vnd.format(stringToInt(
                              _formKey.currentState?.value['discount']) ??
                          0),
                    });
                  }

                  setState(() {
                    _discountType = value!;
                    checkDiscountOrder();

                    updatePaid();
                  });
                },
                children: {
                  DiscountType.percent: Container(
                    child: Text(
                      '%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _discountType == DiscountType.percent
                              ? Colors.white
                              : Colors.black),
                    ),
                  ),
                  DiscountType.price: Container(
                    child: Text(
                      'đ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _discountType == DiscountType.price
                              ? Colors.white
                              : Colors.black),
                    ),
                  )
                },
                groupValue: _discountType,
              )),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              hintText: '0',
              suffixText: _discountType == DiscountType.percent ? '' : '',
            ),
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
                minimumSize: Size(80, 48),
              ),
              onPressed: _isLoading ? null : () => submit(currentRoomType),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
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
                minimumSize: Size(80, 48),
                backgroundColor: Colors.blue,
              ),
              onPressed: _isLoading
                  ? null
                  : () => submit(TableStatus.free, isPay: true),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
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
                minimumSize: Size(80, 48),
              ),
              onPressed: _isLoading ? null : () => submit(currentRoomType),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
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
                minimumSize: Size(80, 48),
              ),
              onPressed: _isLoading ? null : () => submit(TableStatus.using),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
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
              minimumSize: Size(80, 48),
            ),
            onPressed: _isLoading ? null : () => submit(TableStatus.using),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
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
              minimumSize: Size(80, 48),
              backgroundColor: Colors.blue,
            ),
            onPressed:
                _isLoading ? null : () => submit(TableStatus.free, isPay: true),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
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
