import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/account_api.dart';
import 'package:flutter_app/app/networking/cloudinary_api.dart';
import 'package:flutter_app/app/utils/cloudinary.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nylo_framework/nylo_framework.dart';

class InfoSettingPage extends NyStatefulWidget {
  final Controller controller = Controller();
  static const path = '/info_setting_page';
  InfoSettingPage({Key? key}) : super(key: key);

  @override
  State<InfoSettingPage> createState() => _InfoSettingPageState();
}

class _InfoSettingPageState extends State<InfoSettingPage> {
  User get account => widget.data();
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;
  File? _imageFile;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _patchEditData());
    super.initState();
  }

  _patchEditData() {
    final userId = Auth.user<User>()?.id;
    log(userId.toString());
    _formKey.currentState?.patchValue({
      'store_name': account.storeName ?? '',
      'name': account.name ?? '',
      'phone': account.phone ?? '',
      'address': account.address ?? '',
    });
  }

  Future _saveData() async {
    setState(() {
      _loading = true;
    });
    Map<String, dynamic> data = {
      'store_name':
          _formKey.currentState?.fields['store_name']?.value.toString(),
      'name': _formKey.currentState?.fields['name']?.value.toString(),
      'phone': _formKey.currentState?.fields['phone']?.value.toString(),
      'address': _formKey.currentState?.fields['address']?.value.toString(),
    };
    String? imageUrl;
    if (_imageFile != null) {
      try {
        imageUrl = await getImageCloudinaryUrl(_imageFile!);
      } catch (e) {
        log(e.toString());
        CustomToast.showToastWarning(context,
            description: 'Upload ảnh thất bại');
        setState(() {
          _loading = false;
        });
        return;
      }
    }
    if (imageUrl != null) {
      data['image'] = imageUrl;
    } else {
      data['image'] = account.image;
    }
    try {
      await api<AccountApi>((request) => request.updateInfoAccount(data));
      CustomToast.showToastSuccess(context, description: "Cập nhật thành công");

      Navigator.pop(context);
    } catch (e) {
      log(getResponseError(e));
      CustomToast.showToastWarning(context, description: getResponseError(e));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Scaffold(
      appBar: GradientAppBar(
          title: Text(
        'Sửa thông tin',
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      body: SafeArea(
          child: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                15.verticalSpace,
                buildimage(context),
                15.verticalSpace,
                FormBuilderTextField(
                  name: 'name',
                  keyboardType: TextInputType.streetAddress,
                  initialValue: account.name,
                  decoration: InputDecoration(labelText: 'Tên'),
                ),
                15.verticalSpace,
                FormBuilderTextField(
                  name: 'phone',
                  enabled: false,
                  initialValue: account.phone,
                  decoration: InputDecoration(labelText: 'Số điện thoại'),
                ),
                15.verticalSpace,
                FormBuilderTextField(
                  name: 'store_name',
                  keyboardType: TextInputType.streetAddress,
                  decoration: InputDecoration(labelText: 'Tên cửa hàng'),
                ),
                15.verticalSpace,
                FormBuilderTextField(
                  name: 'address',
                  keyboardType: TextInputType.streetAddress,
                  decoration: InputDecoration(labelText: 'Địa chỉ'),
                ),
                15.verticalSpace,
                SizedBox(
                  width: 0.5.sw,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: ThemeColor.get(context).primaryAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _saveData();
                    },
                    child: _loading
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text('Lưu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget buildimage(context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (account.image != null && account.image!.isNotEmpty
                      ? NetworkImage(account.image!)
                      : AssetImage('public/assets/images/placeholder.png'))
                  as ImageProvider,
          onBackgroundImageError: (_, __) {
            setState(() {
              _imageFile = null;
            });
          },
          child: null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Wrap(
                  children: [
                    ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Chọn từ thư viện'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.camera_alt),
                      title: Text('Chụp ảnh'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
