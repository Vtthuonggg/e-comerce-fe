import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/networking/category_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditCategoryPage extends NyStatefulWidget {
  static const path = '/edit_category';
  final controller = Controller();
  EditCategoryPage({super.key});

  @override
  NyState<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends NyState<EditCategoryPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;

  bool get isEditing => widget.data() != null;

  @override
  init() async {
    super.init();

    if (isEditing) {
      _formKey.currentState!.patchValue({
        'name': widget.data()?.name,
        'description': widget.data()?.description,
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _createCategory() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      if (isEditing) {
        await api<CategoryApiService>((request) => request.updateCategory(
            widget.data()!.id, _formKey.currentState!.value));
        CustomToast.showToastSuccess(context,
            description: "Cập nhật danh mục thành công");
        Navigator.of(context).pop();
      } else {
        var res = await api<CategoryApiService>(
            (request) => request.createCategory(_formKey.currentState!.value));
        CustomToast.showToastSuccess(context,
            description: "Tạo danh mục thành công");
        Navigator.of(context).pop(res);
      }
    } catch (error) {
      log(error.toString());
      CustomToast.showToastError(context, description: getResponseError(error));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? "Sửa danh mục" : "Tạo danh mục",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              FormBuilder(
                key: _formKey,
                onChanged: () {
                  _formKey.currentState!.save();
                },
                clearValueOnUnregister: true,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: 'name',
                      decoration: InputDecoration(
                        labelText: 'Tên danh mục',
                      ),
                      keyboardType: TextInputType.name,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    SizedBox(height: 20),
                    FormBuilderTextField(
                      keyboardType: TextInputType.name,
                      name: 'description',
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: ThemeColor.get(context).primaryAccent,
                  ),
                  onPressed: _createCategory,
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : isEditing
                          ? Text("Cập nhật",
                              style: TextStyle(color: Colors.white))
                          : Text(
                              "Tạo danh mục",
                              style: TextStyle(color: Colors.white),
                            )),
              SizedBox(height: 20),
            ],
          ),
        ),
      )),
    );
  }
}
