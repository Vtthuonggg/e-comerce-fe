import 'dart:developer';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/models/supplier.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/add_order_item_card.dart';
import 'package:flutter_app/resources/widgets/select_multi_ingredient.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_app/resources/widgets/select_supplier.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:nylo_framework/nylo_framework.dart';

class AddStorageOrderPage extends NyStatefulWidget {
  static const path = 'order-add';
  final controller = Controller();
  AddStorageOrderPage({super.key});

  @override
  NyState<AddStorageOrderPage> createState() => _AddStorageOrderPageState();
}

class _AddStorageOrderPageState extends NyState<AddStorageOrderPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  final _selectIngMultiKey = GlobalKey<DropdownSearchState<Ingredient>>();
  List<Ingredient> selectedIngredients = [];
  final _selectSupplierKey = GlobalKey<DropdownSearchState<Supplier>>();
  Supplier? selectedSupplier;

  int orderDiscountType = 1; // 1: %, 2: VND
  int statusOrder = 1; // default status
  int paymentType = 1; // 1: tiền mặt, 2: chuyển khoản, 3: quẹt thẻ

  Map<int, int> itemDiscountTypes = {}; // 1: %, 2: VND

  @override
  void initState() {
    super.initState();
  }

  void _initializeDiscountTypeForIngredient(Ingredient ingredient) {
    if (!itemDiscountTypes.containsKey(ingredient.id)) {
      itemDiscountTypes[ingredient.id!] = 1; // default: %
    }
  }

  num _calculateTotalAmount() {
    num total = 0;
    final formData = _formKey.currentState?.value ?? {};

    for (var ing in selectedIngredients) {
      final price =
          stringToInt(formData['price_${ing.id}']?.toString() ?? '0') ?? 0;
      final quantity = ing.quantity ?? 0;
      num itemTotal = price * quantity;

      // Trừ discount của item
      final itemDiscount =
          stringToDouble(formData['discount_${ing.id}']?.toString() ?? '0') ??
              0;
      final itemDiscountType = formData['discount_type_${ing.id}'] as int? ?? 1;
      if (itemDiscount > 0) {
        if (itemDiscountType == 1) {
          // % discount
          itemTotal -= itemTotal * (itemDiscount / 100);
        } else {
          // VND discount
          itemTotal -= itemDiscount;
        }
      }

      total += itemTotal;
    }

    // Trừ discount tổng đơn
    final orderDiscount =
        stringToDouble(formData['order_discount']?.toString() ?? '0') ?? 0;
    if (orderDiscount > 0) {
      if (orderDiscountType == 1) {
        // % discount
        total -= total * (orderDiscount / 100);
      } else {
        // VND discount
        total -= orderDiscount;
      }
    }

    return total;
  }

  Future<void> _createStorageOrder() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      // Validate supplier
      if (selectedSupplier == null) {
        CustomToast.showToastError(context,
            description: "Vui lòng chọn nhà cung cấp");
        return;
      }

      // Validate ingredients
      if (selectedIngredients.isEmpty) {
        CustomToast.showToastError(context,
            description: "Vui lòng chọn ít nhất một nguyên liệu");
        return;
      }

      // Validate quantity cho từng ingredient
      for (var ing in selectedIngredients) {
        if (ing.quantity == null || ing.quantity! <= 0) {
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
          final price =
              stringToInt(formData['price_${ing.id}']?.toString() ?? '0');
          final discount = stringToDouble(
                  formData['discount_${ing.id}']?.toString() ?? '0') ??
              0;
          final discountType = formData['discount_type_${ing.id}'] as int? ?? 1;
          final note = formData['note_${ing.id}']?.toString() ?? '';

          return {
            'ingredient_id': ing.id,
            'quantity': ing.quantity,
            'user_price': price,
            if (discount > 0) 'discount': discount,
            if (discount > 0) 'discount_type': discountType,
            if (note.isNotEmpty) 'note': note,
          };
        }).toList();

        final orderNote = formData['order_note']?.toString() ?? '';
        final orderDiscount =
            stringToDouble(formData['order_discount']?.toString() ?? '0') ?? 0;
        final paymentPrice =
            stringToInt(formData['payment_price']?.toString() ?? '0') ?? 0;

        final payload = {
          'type': 2, // Luôn là 2 cho đơn nhập hàng
          'supplier_id': selectedSupplier!.id,
          if (orderNote.isNotEmpty) 'note': orderNote,
          if (orderDiscount > 0) 'discount': orderDiscount,
          if (orderDiscount > 0) 'discount_type': orderDiscountType,
          'status_order': statusOrder,
          'payment': {
            'type': paymentType,
            'price': paymentPrice,
          },
          'order_detail': orderDetails,
        };

        log('Payload: $payload');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: Text('Tạo đơn nhập hàng')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhà cung cấp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                SizedBox(height: 16),
                IngredientMultiSelect(
                  multiKey: _selectIngMultiKey,
                  selectedItems: selectedIngredients,
                  isShowList: false,
                  onSelect: (items) {
                    setState(() {
                      selectedIngredients = items ?? [];
                      for (var ing in selectedIngredients) {
                        _initializeDiscountTypeForIngredient(ing);
                        if (ing.quantity == null || ing.quantity == 0) {
                          ing.quantity = 1;
                        }
                      }
                    });
                  },
                ),
                SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'order_note',
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú đơn hàng',
                    hintText: 'Nhập ghi chú cho đơn hàng (nếu có)...',
                    prefixIcon: Icon(Icons.note_alt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Trạng thái đơn hàng
                FormBuilderDropdown<int>(
                  name: 'status_order',
                  initialValue: statusOrder,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái đơn hàng',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 1, child: Text('Đang xử lý')),
                    DropdownMenuItem(value: 2, child: Text('Hoàn thành')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      statusOrder = value ?? 1;
                    });
                  },
                ),
                SizedBox(height: 16),

                if (selectedIngredients.isNotEmpty) ...[
                  ...selectedIngredients.map((ingredient) => AddOrderItemCard(
                        ingredient: ingredient,
                        discountType: itemDiscountTypes[ingredient.id] ?? 1,
                        onRemove: () {
                          setState(() {
                            selectedIngredients.removeWhere(
                                (item) => item.id == ingredient.id);
                            itemDiscountTypes.remove(ingredient.id);
                          });
                        },
                        onQuantityChange: (newQuantity) {
                          setState(() {
                            ingredient.quantity = newQuantity;
                          });
                        },
                        onUpdate: () {
                          setState(() {});
                        },
                      )),
                ],
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giảm giá tổng đơn:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: FormBuilderTextField(
                                name: 'order_discount',
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Giảm giá',
                                  hintText: '0',
                                  prefixIcon: Icon(Icons.discount),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  setState(() {}); // Update total
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: FormBuilderDropdown<int>(
                                name: 'order_discount_type',
                                initialValue: orderDiscountType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(value: 1, child: Text('%')),
                                  DropdownMenuItem(
                                      value: 2, child: Text('VND')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    orderDiscountType = value ?? 1;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Tổng tiền
                Card(
                  color: Colors.blue.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          vnd.format(_calculateTotalAmount()),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        FormBuilderDropdown<int>(
                          name: 'payment_type',
                          initialValue: paymentType,
                          decoration: InputDecoration(
                            labelText: 'Phương thức thanh toán *',
                            prefixIcon: Icon(Icons.payment),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(value: 1, child: Text('Tiền mặt')),
                            DropdownMenuItem(
                                value: 2, child: Text('Chuyển khoản')),
                            DropdownMenuItem(value: 3, child: Text('Quẹt thẻ')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              paymentType = value ?? 1;
                            });
                          },
                        ),
                        SizedBox(height: 12),
                        FormBuilderTextField(
                          name: 'payment_price',
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Số tiền thanh toán *',
                            hintText: '0',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText: 'Vui lòng nhập số tiền'),
                            FormBuilderValidators.numeric(
                                errorText: 'Số tiền phải là số'),
                            FormBuilderValidators.min(1,
                                errorText: 'Số tiền phải lớn hơn 0'),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Nút lưu
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
                                strokeWidth: 2,
                              ),
                            ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
