import 'dart:io';
import 'dart:developer';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/Ingredient.dart';
import 'package:flutter_app/app/networking/ingredient_api.dart';
import 'package:flutter_app/app/utils/cloudinary.dart';
import 'package:flutter_app/app/utils/formatters.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EditIngredientPage extends NyStatefulWidget {
  static const path = '/edit_ingredient';
  final controller = Controller();
  EditIngredientPage({Key? key}) : super(key: key);

  @override
  NyState<EditIngredientPage> createState() => _EditIngredientPageState();
}

class _EditIngredientPageState extends NyState<EditIngredientPage> {
  bool get isEdit => widget.data() != null;

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;
  File? _imageFile;
  String? _imageUrl; // existing remote image
  final ImagePicker _picker = ImagePicker();

  @override
  init() async {
    super.init();

    if (isEdit) {
      _patchEditData();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  _patchEditData() async {
    final data = widget.data()['data'] as Ingredient;
    _formKey.currentState?.patchValue({
      'name': data.name ?? '',
      'base_cost': vnd.format(data.baseCost ?? '0'),
      'retail_cost': vnd.format(data.retailCost ?? '0'),
      'unit': data.unit ?? '',
    });

    final img = data.image;
    if (img != null && img.toString().isNotEmpty) {
      setState(() => _imageUrl = img.toString());
    }
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Chọn từ thư viện'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Chụp ảnh'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.close),
              title: Text('Hủy'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      log('Image pick error: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageUrl = null;
    });
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    setState(() => _loading = true);

    final values = _formKey.currentState!.value;

    String imageUrl = _imageUrl ?? '';
    try {
      // if user picked a new file, upload it and get url
      if (_imageFile != null) {
        imageUrl = (await getImageCloudinaryUrl(_imageFile!)) ?? '';
      }
    } catch (e) {
      log('Upload image error: $e');
    }

    final payload = {
      'name': values['name']?.toString().trim(),
      'base_cost': stringToInt(values['base_cost']) ?? 0,
      'retail_cost': stringToInt(values['retail_cost']) ?? 0,
      'in_stock': isEdit ? null : stringToDouble(values['in_stock']) ?? 0,
      'image': imageUrl.isEmpty ? null : imageUrl,
      'unit': values['unit'] ?? '',
    };

    try {
      await api<IngredientApiService>((request) => isEdit
          ? request.updateIngredient(widget.data()['data'].id, payload)
          : request.createIngredient(payload));
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
        title: Text(
          isEdit ? 'Chỉnh sửa nguyên liệu' : 'Thêm nguyên liệu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 12),
                FormBuilder(
                  key: _formKey,
                  onChanged: () => _formKey.currentState?.save(),
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'name',
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'Tên *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.streetAddress,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: 'Vui lòng nhập tên'),
                          FormBuilderValidators.maxLength(255,
                              errorText: 'Tên không được quá 255 ký tự'),
                        ]),
                      ),
                      SizedBox(height: 12),
                      FormBuilderTextField(
                        name: 'base_cost',
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        inputFormatters: [
                          CurrencyTextInputFormatter(locale: 'vi', symbol: ''),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Giá nhập',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 12),
                      FormBuilderTextField(
                        name: 'retail_cost',
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'Giá bán lẻ',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          CurrencyTextInputFormatter(locale: 'vi', symbol: ''),
                        ],
                        keyboardType: TextInputType.number,
                      ),
                      if (!isEdit) ...[
                        SizedBox(height: 12),
                        FormBuilderTextField(
                          name: 'in_stock',
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
                          decoration: InputDecoration(
                            labelText: 'Tồn kho',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,3}')),
                          ],
                        ),
                      ],
                      SizedBox(height: 12),
                      FormBuilderTextField(
                        name: 'unit',
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        keyboardType: TextInputType.streetAddress,
                        decoration: InputDecoration(
                          labelText: 'Đơn vị',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 50,
                      ),
                      if (_imageFile == null &&
                          (_imageUrl == null || _imageUrl!.isEmpty)) ...[
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(Icons.image),
                          label: Text('Chọn ảnh hoặc chụp'),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _imageFile != null
                                    ? Image.file(_imageFile!,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover)
                                    : Image.network(_imageUrl!,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    icon: Container(
                                      height: 28,
                                      width: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                    ),
                                    onPressed: _removeImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onSubmit,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _loading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(isEdit ? 'Cập nhật' : 'Tạo',
                                  style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
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
