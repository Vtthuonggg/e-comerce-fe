import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/models/category.dart';
import 'package:flutter_app/app/models/product.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/category/category_select_multi.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/select_multi_ingredient.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditProductPage extends NyStatefulWidget {
  static const path = '/edit_product';
  final controller = Controller();
  EditProductPage({Key? key}) : super(key: key);

  @override
  NyState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends NyState<EditProductPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  bool get isEdit => widget.data() != null;
  final _selectCateMultiKey = GlobalKey<DropdownSearchState<CategoryModel>>();
  final GlobalKey<CategorytMultiSelectState> _categoryMultiKey =
      GlobalKey<CategorytMultiSelectState>();

  List<CategoryModel> selectedCates = [];
  final _selectIngMultiKey = GlobalKey<DropdownSearchState<Ingredient>>();
  List<Ingredient> selectedIng = [];
  @override
  void initState() {
    super.initState();
    if (isEdit) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _patchDataForEdit(context));
    }
  }

  _patchDataForEdit(BuildContext context) {
    Product? data = widget.data()?['data'] as Product?;
    selectedCates = data?.categories ?? [];
    if (data == null) return;
    _formKey.currentState?.patchValue({
      'name': data.name ?? '',
      'retail_cost': vnd.format(data.retailCost ?? 0),
      'base_cost': vnd.format(data.baseCost ?? 0),
      'stock': roundQuantity(data.stock ?? 0),
      'unit': data.unit ?? '',
    });
    selectedIng = data.ingredients ?? [];
    setState(() {});
  }

  Future saveProduct() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      if (selectedIng
          .where((element) => element.quantity == null || element.quantity == 0)
          .isNotEmpty) {
        CustomToast.showToastError(context,
            description:
                "Vui lòng nhập số lượng cho tất cả nguyên liệu đã chọn");
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final formData = _formKey.currentState!.value;
      var payload = {
        'name': formData['name'],
        'retail_cost': stringToInt(formData['retail_cost'] ?? '0'),
        'base_cost': stringToInt(formData['base_cost'] ?? '0'),
        'stock': formData['stock'] != ''
            ? stringToDouble(formData['stock'].toString())
            : 0,
        'type': formData['type'],
        'unit': formData['unit']?.toString().trim().isEmpty == true
            ? null
            : formData['unit'],
        'category_ids': selectedCates.map((e) => e.id).toList(),
        'ingredients': selectedIng
            .map((e) => {
                  'id': e.id,
                  'quantity': e.quantity ?? 0,
                })
            .toList(),
      };

      try {
        if (isEdit) {
          await api<ProductApiService>((request) =>
              request.updateProduct(widget.data()['data'].id, payload));
        } else {
          await api<ProductApiService>(
              (request) => request.createProduct(payload));
        }
        CustomToast.showToastSuccess(context,
            description: isEdit
                ? "Cập nhật món ăn thành công"
                : "Tạo món ăn thành công");
        pop();
      } catch (e) {
        CustomToast.showToastError(context,
            description: "Có lỗi xảy ra: ${e.toString()}");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void addMultiCategory(List<CategoryModel> listCateSelected) {
    if (listCateSelected.isEmpty) {
      setState(() {
        selectedCates = [];
      });
      return;
    }
    for (var cate in listCateSelected) {
      if (selectedCates.indexWhere((element) => element.id == cate.id) == -1) {
        setState(() {
          selectedCates.add(cate);
        });
      } else {
        selectedCates.removeWhere((i) =>
            listCateSelected
                .firstWhereOrNull((element) => element.id == i.id) ==
            null);
      }
    }
  }

  addMultiIngredient(List<Ingredient> listIngSelected) {
    if (listIngSelected.isEmpty) {
      setState(() {
        selectedIng = [];
      });
      return;
    }
    for (var ing in listIngSelected) {
      if (selectedIng.indexWhere((element) => element.id == ing.id) == -1) {
        setState(() {
          selectedIng.add(ing);
        });
      } else {
        selectedIng.removeWhere((i) =>
            listIngSelected.firstWhereOrNull((element) => element.id == i.id) ==
            null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(isEdit ? 'Chỉnh sửa món ăn' : 'Tạo món ăn',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'name',
                  keyboardType: TextInputType.streetAddress,
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    labelText: 'Tên món ăn *',
                    hintText: 'Nhập tên món ăn',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Vui lòng nhập tên món ăn'),
                    FormBuilderValidators.maxLength(255,
                        errorText: 'Tên món ăn không được quá 255 ký tự'),
                  ]),
                ),

                SizedBox(height: 16),

                // Giá bán
                FormBuilderTextField(
                  name: 'retail_cost',
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    labelText: 'Giá bán *',
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: 'đ',
                  ),
                  inputFormatters: [
                    CurrencyTextInputFormatter(locale: 'vi', symbol: ''),
                  ],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Vui lòng nhập giá bán'),
                    FormBuilderValidators.numeric(
                        errorText: 'Giá bán phải là số'),
                    FormBuilderValidators.min(0,
                        errorText: 'Giá bán phải lớn hơn hoặc bằng 0'),
                  ]),
                ),

                SizedBox(height: 16),

                // Tồn kho
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'stock',
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'Tồn kho',
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'unit',
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        keyboardType: TextInputType.streetAddress,
                        decoration: InputDecoration(
                          labelText: 'Đơn vị tính',
                          hintText: 'VD: cái, kg, lít...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: FormBuilderValidators.maxLength(50,
                            errorText: 'Đơn vị tính không được quá 50 ký tự'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                CategorytMultiSelect(
                  multiKey: _selectCateMultiKey,
                  key: _categoryMultiKey,
                  onSelect: (List<CategoryModel>? listCategory) {
                    addMultiCategory(listCategory ?? []);
                  },
                  selectedItems: selectedCates,
                ),
                SizedBox(height: 16),
                IngredientMultiSelect(
                  multiKey: _selectIngMultiKey,
                  onSelect: (List<Ingredient>? listIngredient) {
                    addMultiIngredient(listIngredient ?? []);
                  },
                  selectedItems: selectedIng,
                ),
                SizedBox(height: 24),

                // Nút Lưu
                ElevatedButton(
                  onPressed: _isLoading ? null : saveProduct,
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
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Đang lưu...'),
                          ],
                        )
                      : Text(
                          isEdit ? 'Cập nhật món ăn' : 'Tạo món ăn',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
