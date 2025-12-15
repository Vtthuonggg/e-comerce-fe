import 'dart:developer';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/models/supplier.dart';
import 'package:flutter_app/app/networking/order_api_service.dart';
import 'package:flutter_app/app/networking/supplier_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/pages/ingredient/select_multi_ingredient.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
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
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  final _selectIngMultiKey = GlobalKey<DropdownSearchState<Ingredient>>();
  List<Ingredient> selectedIngredients = [];

  Supplier? selectedSupplier;

  // Controllers cho order level
  TextEditingController noteController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  int orderDiscountType = 1; // 1: %, 2: VND
  int statusOrder = 1; // default status
  int paymentType = 1; // 1: tiền mặt, 2: chuyển khoản, 3: quẹt thẻ
  TextEditingController paymentPriceController = TextEditingController();

  // Controllers cho từng ingredient
  Map<int, TextEditingController> priceControllers = {};
  Map<int, TextEditingController> itemDiscountControllers = {};
  Map<int, int> itemDiscountTypes = {}; // 1: %, 2: VND
  Map<int, TextEditingController> itemNoteControllers = {};

  @override
  void initState() {
    super.initState();
  }

  void _initializeControllersForIngredient(Ingredient ingredient) {
    if (!priceControllers.containsKey(ingredient.id)) {
      priceControllers[ingredient.id!] = TextEditingController();
      itemDiscountControllers[ingredient.id!] = TextEditingController();
      itemNoteControllers[ingredient.id!] = TextEditingController();
      itemDiscountTypes[ingredient.id!] = 1; // default: %
    }
  }

  num _calculateTotalAmount() {
    num total = 0;
    for (var ing in selectedIngredients) {
      final price = stringToInt(priceControllers[ing.id]?.text ?? '0') ?? 0;
      final quantity = ing.quantity ?? 0;
      num itemTotal = price * quantity;

      // Trừ discount của item
      final itemDiscount =
          stringToDouble(itemDiscountControllers[ing.id]?.text ?? '0') ?? 0;
      final itemDiscountType = itemDiscountTypes[ing.id] ?? 1;
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
    final orderDiscount = stringToDouble(discountController.text) ?? 0;
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

      // Validate quantity và price cho từng ingredient
      for (var ing in selectedIngredients) {
        if (ing.quantity == null || ing.quantity! <= 0) {
          CustomToast.showToastError(context,
              description: "Vui lòng nhập số lượng cho ${ing.name}");
          return;
        }

        final priceText = priceControllers[ing.id]?.text ?? '';
        if (priceText.isEmpty || (stringToInt(priceText) ?? 0) <= 0) {
          CustomToast.showToastError(context,
              description: "Vui lòng nhập giá nhập cho ${ing.name}");
          return;
        }
      }

      // Validate payment price
      final paymentPrice = stringToInt(paymentPriceController.text) ?? 0;
      if (paymentPrice <= 0) {
        CustomToast.showToastError(context,
            description: "Vui lòng nhập số tiền thanh toán");
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Build order_detail
        final orderDetails = selectedIngredients.map((ing) {
          final price = stringToInt(priceControllers[ing.id]?.text ?? '0');
          final discount =
              stringToDouble(itemDiscountControllers[ing.id]?.text ?? '0') ?? 0;
          final discountType = itemDiscountTypes[ing.id] ?? 1;
          final note = itemNoteControllers[ing.id]?.text ?? '';

          return {
            'ingredient_id': ing.id,
            'quantity': ing.quantity,
            'user_price': price,
            if (discount > 0) 'discount': discount,
            if (discount > 0) 'discount_type': discountType,
            if (note.isNotEmpty) 'note': note,
          };
        }).toList();

        final orderNote = noteController.text;
        final orderDiscount = stringToDouble(discountController.text) ?? 0;

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
                // Chọn nhà cung cấp
                _buildSupplierDropdown(),
                SizedBox(height: 16),

                // Ghi chú đơn hàng
                TextFormField(
                  controller: noteController,
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
                DropdownButtonFormField<int>(
                  value: statusOrder,
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

                // Chọn nguyên liệu
                IngredientMultiSelect(
                  multiKey: _selectIngMultiKey,
                  selectedItems: selectedIngredients,
                  onSelect: (items) {
                    setState(() {
                      selectedIngredients = items ?? [];
                      // Initialize controllers for new ingredients
                      for (var ing in selectedIngredients) {
                        _initializeControllersForIngredient(ing);
                      }
                    });
                  },
                ),
                SizedBox(height: 16),

                // Danh sách chi tiết nguyên liệu đã chọn với giá, discount
                if (selectedIngredients.isNotEmpty) ...[
                  Text(
                    'Chi tiết đơn hàng:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...selectedIngredients
                      .map((ing) => _buildIngredientDetailCard(ing)),
                  SizedBox(height: 16),

                  // Giảm giá tổng đơn
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
                                child: TextFormField(
                                  controller: discountController,
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
                                child: DropdownButtonFormField<int>(
                                  value: orderDiscountType,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    isDense: true,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                        value: 1, child: Text('%')),
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
                          DropdownButtonFormField<int>(
                            value: paymentType,
                            decoration: InputDecoration(
                              labelText: 'Phương thức thanh toán *',
                              prefixIcon: Icon(Icons.payment),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                  value: 1, child: Text('Tiền mặt')),
                              DropdownMenuItem(
                                  value: 2, child: Text('Chuyển khoản')),
                              DropdownMenuItem(
                                  value: 3, child: Text('Quẹt thẻ')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                paymentType = value ?? 1;
                              });
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: paymentPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Số tiền thanh toán *',
                              hintText: '0',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

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

  Widget _buildSupplierDropdown() {
    return DropdownSearch<Supplier>(
      asyncItems: (String filter) async {
        var res = await api<SupplierApiService>(
          (request) => request.listSupplier(
            filter.isEmpty ? null : filter,
            1,
            20,
          ),
        );
        return res['data']
            .map<Supplier>((data) => Supplier.fromJson(data))
            .toList();
      },
      itemAsString: (Supplier supplier) => supplier.name ?? '',
      onChanged: (Supplier? supplier) {
        setState(() {
          selectedSupplier = supplier;
        });
      },
      selectedItem: selectedSupplier,
      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Tìm nhà cung cấp...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        itemBuilder: (context, item, isSelected) => ListTile(
          title: Text(item.name ?? ''),
          subtitle: item.phone != null ? Text(item.phone!) : null,
          trailing: isSelected ? Icon(Icons.check_circle) : null,
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Nhà cung cấp *',
          hintText: 'Chọn nhà cung cấp',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: Icon(Icons.business),
        ),
      ),
    );
  }

  Widget _buildIngredientDetailCard(Ingredient ingredient) {
    _initializeControllersForIngredient(ingredient);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên và số lượng
            Row(
              children: [
                Expanded(
                  child: Text(
                    ingredient.name ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${roundQuantity(ingredient.quantity ?? 0)} ${ingredient.unit ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Giá nhập
            TextFormField(
              controller: priceControllers[ingredient.id!],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Giá nhập *',
                hintText: '0',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {}); // Update total
              },
            ),
            SizedBox(height: 12),

            // Discount và discount type
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: itemDiscountControllers[ingredient.id!],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
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
                  child: DropdownButtonFormField<int>(
                    value: itemDiscountTypes[ingredient.id!] ?? 1,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: 1, child: Text('%')),
                      DropdownMenuItem(value: 2, child: Text('VND')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        itemDiscountTypes[ingredient.id!] = value ?? 1;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Ghi chú
            TextFormField(
              controller: itemNoteControllers[ingredient.id!],
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Nhập ghi chú (nếu có)...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    discountController.dispose();
    paymentPriceController.dispose();
    for (var controller in priceControllers.values) {
      controller.dispose();
    }
    for (var controller in itemDiscountControllers.values) {
      controller.dispose();
    }
    for (var controller in itemNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
