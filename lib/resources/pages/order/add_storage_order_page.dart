import 'dart:developer';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/models/supplier.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/order_ingredient_item.dart';
import 'package:flutter_app/resources/widgets/select_multi_ingredient.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_app/resources/widgets/select_supplier.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:nylo_framework/nylo_framework.dart';

class AddStorageOrderPage extends NyStatefulWidget {
  static const path = 'order-add';
  final controller = Controller();
  AddStorageOrderPage({super.key});

  @override
  NyState<AddStorageOrderPage> createState() => _AddStorageOrderPageState();
}

class _AddStorageOrderPageState extends NyState<AddStorageOrderPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  final _selectIngMultiKey = GlobalKey<DropdownSearchState<Ingredient>>();
  List<Ingredient> selectedIngredients = [];
  final _selectSupplierKey = GlobalKey<DropdownSearchState<Supplier>>();
  Supplier? selectedSupplier;

  int orderDiscountType = 1; // 1: %, 2: VND
  int statusOrder = 1; // default status
  int paymentType = 1; // 1: tiền mặt, 2: chuyển khoản, 3: quẹt thẻ

  final discountController = TextEditingController();
  final vatController = TextEditingController();
  DiscountType _discountType = DiscountType.percent;
  @override
  void initState() {
    super.initState();
  }

  num getTotalQty() {
    num total = 0;
    for (var ing in selectedIngredients) {
      total += ing.quantity ?? 0;
    }
    return total;
  }

  Future<void> _createStorageOrder() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      // Validate ingredients
      if (selectedIngredients.isEmpty) {
        CustomToast.showToastError(context,
            description: "Vui lòng chọn ít nhất một nguyên liệu");
        return;
      }

      // Validate quantity cho từng ingredient
      for (var ing in selectedIngredients) {
        if (ing.quantity <= 0) {
          CustomToast.showToastError(context,
              description: "Vui lòng nhập số lượng cho ${ing.name}");
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;

        // Build order_detail
        final orderDetails = selectedIngredients.map((ing) {
          final price = ing.baseCost ?? 0;
          final discount = ing.discount ?? 0;
          final discountType = ing.discountType ?? DiscountType.percent;
          final note = ing.productNote;

          return {
            'ingredient_id': ing.id,
            'quantity': ing.quantity,
            'price': price,
            'discount': discount,
            'discount_type': discountType.getValueRequest(),
            'note': note,
          };
        }).toList();

        final orderNote = formData['note']?.toString() ?? '';
        final orderDiscount = _discountType == DiscountType.percent
            ? stringToDouble(formData['discount'])
            : stringToInt(formData['discount']);
        final paymentPrice = stringToInt(formData['paid'] ?? '0') ?? 0;

        final payload = {
          'type': 2,
          'supplier_id': selectedSupplier?.id,
          'note': orderNote,
          'discount': orderDiscount ?? 0,
          'discount_type': orderDiscountType,
          'status_order': statusOrder,
          'payment': {
            'type': paymentType,
            'price': paymentPrice,
          },
          'order_detail': orderDetails,
        };

        await api<OrderApiService>((request) => request.createOrder(payload));

        CustomToast.showToastSuccess(context,
            description: "Tạo đơn nhập hàng thành công");

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        log(e.toString());
        CustomToast.showToastError(context, description: getResponseError(e));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void checkOnChange() {
    if (_isLoading) return;

    int discountOrder =
        stringToInt(_formKey.currentState?.value['discount']) ?? 0;
    if (_discountType == DiscountType.price &&
        discountOrder > getTotalPrice()) {
      _formKey.currentState
          ?.patchValue({'discount': vnd.format(getTotalPrice())});
    }
  }

  void updatePaid() {
    //update vat
    num totalVat = 0;
    for (var item in selectedIngredients) {
      dynamic quantityValue = item.quantity.toString();
      num baseCost = item.baseCost ?? 0;

      num quantity = num.tryParse(quantityValue) ?? 0;
      num total = baseCost * quantity;
      num discountVal = (item.discount ?? 0);
      num discountPrice = item.discountType == DiscountType.percent
          ? total * discountVal / 100
          : discountVal;

      total = total - discountPrice;
      var vat = item.vat ?? 0;
      if (vat > 0) {
        totalVat += total * vat / 100;
      }
    }

    vatController.text = vnd.format(totalVat);

    num finalPrice = getFinalPrice();
    _formKey.currentState!.patchValue({
      'paid': vnd.format(roundMoney(finalPrice)).isEmpty
          ? '0'
          : vnd.format(roundMoney(finalPrice))
    });
  }

  num getTotalPrice() {
    num total = 0;
    selectedIngredients.forEach((item) {
      total += getPrice(item);
    });
    return total;
  }

  num getPrice(Ingredient item) {
    dynamic baseCostValue = item.txtPrice.text.isNotEmpty
        ? item.txtPrice.text.replaceAll('.', '')
        : _formKey.currentState?.value['${item.id}.base_cost'];
    num baseCost = stringToInt(baseCostValue) ?? item.baseCost ?? 0;
    dynamic quantityValue = item.quantity.toString();
    num quantity = num.tryParse(quantityValue) ?? 0;
    num price = baseCost;
    num total = price * quantity;

    // discount
    num discountVal = (item.discount ?? 0);
    num discountPrice = item.discountType == DiscountType.percent
        ? total * discountVal / 100
        : discountVal;
    total = total - discountPrice;
    var vat = item.vat ?? 0;
    if (vat > 0) {
      total = total + total * vat / 100;
    }
    return total;
  }

  num getFinalPrice() {
    num total = getTotalPrice();
    num discountVal = _discountType == DiscountType.percent
        ? stringToDouble(discountController.text) ?? 0
        : stringToInt(discountController.text) ?? 0;
    // apply discount
    num discountPrice = _discountType == DiscountType.percent
        ? total * discountVal / 100
        : discountVal;
    total = total - discountPrice;
    return total;
  }

  num getPaid() {
    final value = _formKey.currentState?.value['paid'];

    final result = stringToInt(value) ?? 0;
    return result;
  }

  num getDebt() {
    final paid = getPaid();
    if (paid == 0) {
      return getFinalPrice();
    }
    num debt = roundMoney(getFinalPrice()) - roundMoney(paid);
    return debt;
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
          discountController.selection = TextSelection.fromPosition(
            TextPosition(offset: discountController.text.length),
          );
        }
      });

      return;
    }

    if (_discountType == DiscountType.percent && discount > 100) {
      Future.delayed(Duration(milliseconds: 100), () {
        discountController.text = '100';
        discountController.selection = TextSelection.fromPosition(
            TextPosition(offset: discountController.text.length));
      });
      return;
    }
    if (mounted) {
      setState(() {});
      updatePaid();
    }
  }

  void checkDiscountItem(Ingredient item) {
    if (_isLoading) return;

    num currentPrice = item.baseCost ?? 0;
    num discount = item.discount ?? 0;
    if (item.discountType == DiscountType.price &&
        discount > currentPrice * item.quantity) {
      Future.delayed(Duration(milliseconds: 100), () {
        String currentText =
            _formKey.currentState?.value['${item.id}.discount'];
        if (currentText.isNotEmpty) {
          _formKey.currentState
              ?.patchValue({'${item.id}.discount': vnd.format(currentPrice)});
        }
      });

      return;
    }

    if (item.discountType == DiscountType.percent && discount > 100) {
      CustomToast.showToastError(context,
          description: "Chiết khấu không được lớn hơn 100%");
      Future.delayed(Duration(milliseconds: 100), () {
        _formKey.currentState?.patchValue({'${item.id}.discount': '100'});
      });
      return;
    }
    if (mounted) {
      setState(() {});
      updatePaid();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: Text('Tạo đơn nhập hàng')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
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
                  _buildSupplierSection(),
                  SizedBox(height: 20),
                  IngredientMultiSelect(
                    multiKey: _selectIngMultiKey,
                    selectedItems: selectedIngredients,
                    isShowList: false,
                    onSelect: (items) {
                      setState(() {
                        selectedIngredients = items ?? [];
                        for (var ing in selectedIngredients) {
                          if (ing.quantity == 0) {
                            ing.quantity = 1;
                          }
                        }
                      });
                      updatePaid();
                    },
                  ),
                  SizedBox(height: 16),

                  if (selectedIngredients.isNotEmpty) ...[
                    ...selectedIngredients.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return OrderIngredientItem(
                        key: ValueKey(item.id),
                        item: item,
                        index: index,
                        updatePaid: () => updatePaid(),
                        costType: CostType.base,
                        removeItem: (ing) {
                          setState(() {
                            item.discount = item.coppyDiscount;
                            item.baseCost = item.copyBaseCost;
                            selectedIngredients
                                .removeWhere((item) => item.id == ing.id);
                          });
                        },
                        onMinusQuantity: () {
                          if (item.quantity >= 1) {
                            String newQuantityStr =
                                (item.quantity - 1).toStringAsFixed(3);
                            num newQuantity =
                                stringToDouble(newQuantityStr) ?? 0;
                            if (newQuantity == newQuantity.floor()) {
                              item.quantity = newQuantity.toInt();
                            } else {
                              item.quantity = newQuantity.toDouble();
                            }
                            if (item.discountType == DiscountType.price) {
                              final currentValue = _formKey
                                  .currentState?.value['${item.id}.discount'];
                              item.discount = (stringToInt(currentValue) ?? 0) *
                                  item.quantity;
                            }
                            _formKey.currentState?.patchValue(
                                {'${item.id}.quantity': '${item.quantity}'});
                            updatePaid();
                          }
                        },
                        getPrice: () => getPrice(item),
                        onChangeQuantity: (value) {
                          setState(() {
                            item.quantity = stringToDouble(value) ?? 0;
                          });
                          updatePaid();
                        },
                        onIncreaseQuantity: () {
                          String newQuantityStr =
                              (item.quantity + 1).toStringAsFixed(3);
                          num newQuantity = stringToDouble(newQuantityStr) ?? 0;
                          if (newQuantity == newQuantity.floor()) {
                            item.quantity = newQuantity.toInt();
                          } else {
                            item.quantity = newQuantity;
                          }
                          if (item.discountType == DiscountType.price) {
                            final currentValue = _formKey
                                .currentState?.value['${item.id}.discount'];
                            item.discount = (stringToInt(currentValue) ?? 0) *
                                item.quantity;
                          }
                          _formKey.currentState?.patchValue(
                              {'${item.id}.quantity': '${item.quantity}'});
                          updatePaid();
                        },
                        onChangePrice: (value) {
                          item.baseCost = stringToInt(value) ?? 0;

                          updatePaid();
                          checkOnChange();
                          setState(() {});
                        },
                        onChangeDiscount: (value) {
                          item.discount =
                              item.discountType == DiscountType.percent
                                  ? (stringToDouble(value) ?? 0)
                                  : (stringToInt(value) ?? 0) * item.quantity;
                          checkDiscountItem(item);
                          checkDiscountOrder();
                          updatePaid();
                          setState(() {});
                        },
                        onChangeDiscountType: (value) {
                          if (value != null) {
                            setState(() {
                              item.discountType = value;
                            });
                          }
                          updatePaid();
                        },
                      );
                    }),
                  ],

                  SizedBox(height: 16),
                  Divider(),
                  buildSummary(),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trạng thái',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left),
                      SizedBox(
                        width: 180,
                        height: 40,
                        child: FormBuilderDropdown<int>(
                          name: 'status_order',
                          initialValue: 1,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: ThemeColor.get(context).primaryAccent,
                              ),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                'Hoàn thành',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                'Chờ xác nhận',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'note',
                    maxLines: 3,
                    minLines: 3,
                    cursorColor: ThemeColor.get(context).primaryAccent,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: 'Nhập ghi chú',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Thông tin thanh toán
                  Text(
                    'Thông tin thanh toán:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _createStorageOrder,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: ThemeColor.get(context).primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  )),
                              SizedBox(width: 12),
                              Text('Đang tạo đơn...'),
                            ],
                          )
                        : Center(
                            child: Text(
                              'Tạo đơn nhập hàng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierSection() {
    return ListTileTheme(
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
      dense: true,
      child: ExpansionTile(
        shape: Border.all(color: Colors.transparent),
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: true,
        title: Text(
          'Thông tin nhà cung cấp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        children: [
          SizedBox(height: 8),
          SupplierSelect(
            selectKey: _selectSupplierKey,
            selectedItem: selectedSupplier,
            onSelect: (Supplier? supplier) {
              setState(() {
                selectedSupplier = supplier;
              });
            },
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget buildSummary() {
    return Column(
      children: [
        Row(
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
                keyboardType: TextInputType.numberWithOptions(
                    decimal: true, signed: true),
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
                          'discount': discount == 0.0
                              ? ''
                              : discount.toStringAsFixed(0),
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
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('VAT', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 40,
              width: 180,
              child: Builder(
                builder: (fieldContext) => FormBuilderTextField(
                  name: 'vat',
                  readOnly: true,
                  controller: vatController,
                  onTap: () {
                    RenderBox renderBox =
                        fieldContext.findRenderObject() as RenderBox;
                    Offset position = renderBox.localToGlobal(Offset.zero);
                    showDetailVat(fieldContext, position);
                  },
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {});
                      updatePaid();
                    }
                  },
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    suffixText: 'đ',
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Chi phí khác', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 180,
              height: 40,
              child: FormBuilderTextField(
                name: 'other_fee',
                readOnly: true,
                initialValue: '0',
                onTap: () {
                  // _showDialogOtherFee();
                },
                inputFormatters: [
                  CurrencyTextInputFormatter(
                    locale: 'vi',
                    symbol: '',
                  )
                ],
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: ThemeColor.get(context).primaryAccent,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixText: 'đ',
                ),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tổng tiền T.Toán',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 40,
              width: 180,
              child: FormBuilderTextField(
                name: '',
                enabled: false,
                controller: TextEditingController(
                    text: vndCurrency
                        .format(roundMoney(getFinalPrice()))
                        .replaceAll('vnđ', 'đ')),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintText: '',
                  suffixText: '',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đã T.Toán', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                    height: 40,
                    width: 180.0,
                    child: Column(
                      children: [
                        Expanded(
                            child: FormBuilderTextField(
                          keyboardType: TextInputType.number,
                          initialValue: '0',
                          name: 'paid',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                          onTap: () {
                            _formKey.currentState!.patchValue({
                              'paid': '',
                            });
                          },
                          onChanged: (vale) {
                            setState(() {});
                          },
                          inputFormatters: [
                            CurrencyTextInputFormatter(
                              locale: 'vi',
                              symbol: '',
                            )
                          ],
                          decoration: InputDecoration(
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            suffixText: 'đ',
                          ),
                        )),
                      ],
                    )),
              ],
            ))
          ],
        ),
        SizedBox(height: 12),
        if (getDebt() != 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Còn nợ', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 40,
                width: 180,
                child: FormBuilderTextField(
                  name: '',
                  enabled: false,
                  controller: TextEditingController(
                      text:
                          vndCurrency.format(getDebt()).replaceAll('vnđ', 'đ')),
                  // initialValue: vndCurrency.format(getDebt()),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    hintText: '',
                    suffixText: '',
                  ),
                ),
              ),
              // Text(vndCurrency.format(getDebt()),
              //     style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        SizedBox(
          height: 12.0,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Hình thức T.Toán',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            width: 180,
            height: 40,
            child: FormBuilderDropdown(
              name: 'payment_type',
              initialValue: 1,
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text(
                    'Tiền mặt',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(
                    'Chuyển khoản',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text(
                    'Quẹt thẻ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ])
      ],
    );
  }

  void showDetailVat(context, Offset position) async {
    final vatItems = selectedIngredients
        .where((item) => item.vat != null && item.vat! > 0)
        .toList();
    getVatPrice(Ingredient item) {
      num baseCost = item.baseCost ?? 0;

      dynamic quantityValue = item.quantity.toString();

      num quantity = num.tryParse(quantityValue) ?? 0;
      num total = baseCost * quantity;
      num discountVal = (item.discount ?? 0);
      num discountPrice = item.discountType == DiscountType.percent
          ? total * discountVal / 100
          : discountVal;
      // apply discount
      total = total - discountPrice;
      var vat = item.vat ?? 0;
      return total * vat / 100;
    }

    await showMenu(
      context: context,
      color: Colors.white,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: vatItems.isEmpty
                ? [Text('Không có món ăn chịu VAT')]
                : vatItems
                    .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${item.name ?? ''}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text: ': ',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                              TextSpan(
                                text: '${item.vat ?? ''}%',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500),
                              ),
                              TextSpan(
                                text: ' → ',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: vndCurrency.format(getVatPrice(item)),
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )))
                    .toList(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
