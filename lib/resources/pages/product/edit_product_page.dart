import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/networking/product_api.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
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

  Future saveProduct() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final formData = _formKey.currentState!.value;

      var payload = {
        'name': formData['name'],
        'retail_cost': stringToInt(formData['retail_cost']),
        'base_cost': stringToInt(formData['base_cost']),
        'stock': formData['stock'] != ''
            ? stringToDouble(formData['stock'].toString())
            : 0,
        'type': formData['type'],
        'unit': formData['unit']?.toString().trim().isEmpty == true
            ? null
            : formData['unit'],
      };

      try {
        await api<ProductApiService>(
            (request) => request.createProduct(payload));

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
                  decoration: InputDecoration(
                    labelText: 'Giá bán *',
                    hintText: 'Nhập giá bán',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: 'VNĐ',
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

                // Giá nhập
                FormBuilderTextField(
                  name: 'base_cost',
                  decoration: InputDecoration(
                    labelText: 'Giá nhập *',
                    hintText: 'Nhập giá mua vào',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixText: 'VNĐ',
                  ),
                  inputFormatters: [
                    CurrencyTextInputFormatter(locale: 'vi', symbol: ''),
                  ],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'Vui lòng nhập giá gốc'),
                    FormBuilderValidators.numeric(
                        errorText: 'Giá gốc phải là số'),
                    FormBuilderValidators.min(0,
                        errorText: 'Giá gốc phải lớn hơn hoặc bằng 0'),
                  ]),
                ),

                SizedBox(height: 16),

                // Tồn kho
                FormBuilderTextField(
                  name: 'stock',
                  decoration: InputDecoration(
                    labelText: 'Số lượng tồn kho',
                    hintText: 'Nhập số lượng tồn kho',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),

                SizedBox(height: 16),

                // Đơn vị
                FormBuilderTextField(
                  name: 'unit',
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

                SizedBox(height: 16),

                // Loại món ăn
                FormBuilderRadioGroup<int>(
                  name: 'type',
                  decoration: InputDecoration(
                    labelText: 'Loại món ăn *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  initialValue: 1,
                  options: [
                    FormBuilderFieldOption(value: 1, child: Text('Loại 1')),
                    FormBuilderFieldOption(value: 2, child: Text('Loại 2')),
                  ],
                  validator: FormBuilderValidators.required(
                      errorText: 'Vui lòng chọn loại món ăn'),
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
