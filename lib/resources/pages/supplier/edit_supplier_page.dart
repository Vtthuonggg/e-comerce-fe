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
    final theme = Theme.of(context);
    final primary = ThemeColor.get(context).primaryAccent;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: GradientAppBar(
        title: Text(
          isEdit ? 'Sửa nhà cung cấp' : 'Thêm nhà cung cấp',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceVariant.withOpacity(0.35),
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primary.withOpacity(.12),
                          radius: 26,
                          child: Icon(
                            Icons.store_outlined,
                            color: primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit
                                    ? 'Cập nhật thông tin nhà cung cấp'
                                    : 'Tạo mới nhà cung cấp',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Điền đầy đủ các thông tin dưới đây để đảm bảo dữ liệu chính xác.',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            isEdit ? Icons.edit : Icons.add,
                            size: 18,
                            color: primary,
                          ),
                          label:
                              Text(isEdit ? 'Chế độ chỉnh sửa' : 'Chế độ tạo'),
                          backgroundColor: primary.withOpacity(.08),
                          labelStyle: theme.textTheme.bodyMedium
                              ?.copyWith(color: primary),
                        ),
                        Chip(
                          avatar: Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          label: const Text('Thông tin bảo mật'),
                          backgroundColor: theme.colorScheme.secondaryContainer
                              .withOpacity(.25),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        child: FormBuilder(
                          key: _formKey,
                          onChanged: () => _formKey.currentState?.save(),
                          child: Column(
                            children: [
                              FormBuilderTextField(
                                name: 'name',
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Tên nhà cung cấp',
                                  hintText: 'Ví dụ: Công ty ABC',
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceVariant
                                      .withOpacity(.3),
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                keyboardType: TextInputType.name,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.maxLength(255),
                                ]),
                              ),
                              const SizedBox(height: 18),
                              FormBuilderTextField(
                                name: 'phone',
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Số điện thoại',
                                  hintText: '0909 123 456',
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceVariant
                                      .withOpacity(.3),
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.maxLength(20),
                                ]),
                              ),
                              const SizedBox(height: 18),
                              FormBuilderTextField(
                                name: 'address',
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: 'Địa chỉ',
                                  hintText: 'Số nhà, đường, thành phố...',
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceVariant
                                      .withOpacity(.3),
                                  prefixIcon:
                                      const Icon(Icons.location_on_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                keyboardType: TextInputType.streetAddress,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.maxLength(255),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: theme.colorScheme.surfaceVariant
                                  .withOpacity(.5),
                              foregroundColor:
                                  theme.colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _loading ? null : _saveSupplier,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _loading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      isEdit
                                          ? 'Lưu thay đổi'
                                          : 'Tạo nhà cung cấp',
                                      key: const ValueKey('label'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ứng dụng sẽ tự động đồng bộ thông tin với các module bán hàng.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
