import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/employee.dart';
import 'package:flutter_app/app/networking/employee_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditEmployeePage extends NyStatefulWidget {
  static const path = '/edit-employee';
  final controller = Controller();
  EditEmployeePage({super.key});

  @override
  NyState<EditEmployeePage> createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends NyState<EditEmployeePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;
  Employee? employee;
  bool isEdit = false;
  bool _isPasswordVisible = false;
  bool _showPasswordField = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = widget.data() as Employee?;
      if (data != null) {
        employee = data;
        isEdit = true;
        _patchEditData();
      }
    });
  }

  void _patchEditData() {
    if (employee == null) return;
    _formKey.currentState?.patchValue({
      'name': employee!.name ?? '',
      'phone': employee!.phone ?? '',
    });
    setState(() {});
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _loading = true);

      try {
        final formData = _formKey.currentState!.value;

        final payload = {
          'name': formData['name'],
          'phone': formData['phone'],
          if (_showPasswordField && formData['password'] != null)
            'password': formData['password'],
        };
        log(payload.toString());
        await api<EmployeeApiService>((request) => isEdit
            ? request.updateEmployee(employee!.id!, payload)
            : request.createEmployee(payload));

        CustomToast.showToastSuccess(context,
            description: isEdit
                ? 'Cập nhật nhân viên thành công'
                : 'Thêm nhân viên thành công');

        Navigator.of(context).pop(true);
      } catch (e) {
        log(e.toString());
        CustomToast.showToastError(context, description: getResponseError(e));
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(
          isEdit ? 'Sửa nhân viên' : 'Thêm nhân viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),

                  // Form fields
                  FormBuilderTextField(
                    name: 'name',
                    decoration: InputDecoration(
                      labelText: 'Họ và tên *',
                      hintText: 'Nhập họ tên nhân viên',
                      prefixIcon: Icon(IconsaxPlusLinear.user),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập tên'),
                    ]),
                  ),
                  SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'phone',
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại *',
                      hintText: '0987654321',
                      prefixIcon: Icon(IconsaxPlusLinear.call),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập số điện thoại'),
                    ]),
                  ),
                  SizedBox(height: 16),

                  // Password toggle switch
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(IconsaxPlusLinear.lock,
                                color: Colors.grey[700], size: 20),
                            SizedBox(width: 12),
                            Text(
                              isEdit ? 'Đổi mật khẩu' : 'Thiết lập mật khẩu',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _showPasswordField,
                          onChanged: (value) {
                            setState(() {
                              _showPasswordField = value;
                              if (!value) {
                                _formKey.currentState?.fields['password']
                                    ?.didChange(null);
                              }
                            });
                          },
                          activeColor: ThemeColor.get(context).primaryAccent,
                        ),
                      ],
                    ),
                  ),

                  // Password field - only show if toggle is on
                  if (_showPasswordField) ...[
                    SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'password',
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu *',
                        hintText: 'Nhập mật khẩu',
                        prefixIcon: Icon(IconsaxPlusLinear.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? IconsaxPlusLinear.eye
                                : IconsaxPlusLinear.eye_slash,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                            errorText: 'Vui lòng nhập mật khẩu'),
                        FormBuilderValidators.minLength(6,
                            errorText: 'Mật khẩu phải có ít nhất 6 ký tự'),
                      ]),
                    ),
                  ],

                  SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColor.get(context).primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(IconsaxPlusLinear.tick_circle),
                                SizedBox(width: 8),
                                Text(
                                  isEdit ? 'Cập nhật' : 'Thêm mới',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
