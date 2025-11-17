import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/Supplier.dart';
import 'package:flutter_app/app/networking/supplier_api.dart';

import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditSupplierPage extends NyStatefulWidget {
  static const path = '/edit-supplier';
  final controller = Controller();
  EditSupplierPage({super.key});

  @override
  NyState<EditSupplierPage> createState() => _EditSupplierPageState();
}

class _EditSupplierPageState extends NyState<EditSupplierPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;

  bool get isEdit => widget.data() != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _patchEditData());
  }

  void _patchEditData() {
    final data = widget.data()?['data'] as Supplier?;
    if (data == null) return;
    _formKey.currentState?.patchValue({
      'name': data.name ?? '',
      'phone': data.phone ?? '',
      'address': data.address ?? '',
    });
  }

  Future<void> _saveSupplier() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    if (_loading) return;

    setState(() => _loading = true);

    final values = _formKey.currentState!.value;
    final payload = {
      'name': values['name']?.toString().trim(),
      'phone': values['phone']?.toString().trim(),
      'address': values['address']?.toString().trim(),
    };

    try {
      await api<SupplierApiService>((request) => isEdit
          ? request.updateSupplier(widget.data()['data'].id, payload)
          : request.createSupplier(payload));
      Navigator.of(context).pop();
    } catch (e) {
      log(e.toString());
      CustomToast.showToastError(context, description: getResponseError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: Text(isEdit ? 'Sửa nhà cung cấp' : 'Thêm nhà cung cấp',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                FormBuilder(
                  key: _formKey,
                  onChanged: () => _formKey.currentState?.save(),
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'name',
                        decoration: const InputDecoration(labelText: 'Tên'),
                        keyboardType: TextInputType.name,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.maxLength(255),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'phone',
                        decoration:
                            const InputDecoration(labelText: 'Số điện thoại'),
                        keyboardType: TextInputType.phone,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.maxLength(20),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'address',
                        decoration: const InputDecoration(labelText: 'Địa chỉ'),
                        keyboardType: TextInputType.streetAddress,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.maxLength(255),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: ThemeColor.get(context).primaryAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: _saveSupplier,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEdit ? 'Cập nhật' : 'Tạo',
                          style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
