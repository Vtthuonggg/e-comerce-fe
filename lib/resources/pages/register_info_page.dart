import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/events/login_event.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/account_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/extensions.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nylo_framework/nylo_framework.dart';

class RegisterInfoPage extends NyStatefulWidget {
  final Controller controller = Controller();
  static const path = '/register_info_page';

  RegisterInfoPage({Key? key}) : super(key: key);

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

class _RegisterInfoPageState extends NyState<RegisterInfoPage> {
  bool _loading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _errorMessage = '';

  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  String? email;
  String? otp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      email = widget.data()['email'] as String?;
      otp = widget.data()['otp'] as String?;
      _emailController.text = email ?? '';
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu không trùng khớp';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    final payload = {
      'email': email,
      'otp': otp,
      'name': _nameController.text,
      'password': _passwordController.text,
      'phone': _phoneController.text,
    };

    try {
      await api<AccountApi>((request) => request.registerWithOtp(payload));
      CustomToast.showToastSuccess(context, description: "Đăng ký thành công");
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() {
        _errorMessage = getResponseError(e);
      });
      CustomToast.showToastError(context, description: _errorMessage);
      log(e.toString());
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: Text('Thông tin đăng ký'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                20.verticalSpace,
                Text(
                  'Hoàn tất đăng ký',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.color.primaryAccent),
                ),
                12.verticalSpace,
                TextField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    disabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _nameController,
                  cursorColor: context.color.primaryAccent,
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      hintText: 'VD: Nguyễn Văn A',
                      floatingLabelStyle: TextStyle(
                        color: context.color.primaryAccent,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: context.color.primaryAccent,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: context.color.primaryAccent,
                        ),
                      )),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _phoneController,
                  cursorColor: context.color.primaryAccent,
                  keyboardType: TextInputType.phone,
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'VD: 0987654321',
                      floatingLabelStyle: TextStyle(
                        color: context.color.primaryAccent,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: context.color.primaryAccent,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: context.color.primaryAccent,
                        ),
                      )),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  cursorColor: context.color.primaryAccent,
                  obscureText: !_isPasswordVisible,
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    floatingLabelStyle: TextStyle(
                      color: context.color.primaryAccent,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: context.color.primaryAccent,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: context.color.primaryAccent,
                      ),
                    ),
                    suffix: GestureDetector(
                      onTap: _togglePasswordVisibility,
                      child: Icon(
                        _isPasswordVisible
                            ? FontAwesomeIcons.eyeSlash
                            : FontAwesomeIcons.solidEye,
                        color: Colors.black26,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _confirmPasswordController,
                  keyboardType: TextInputType.visiblePassword,
                  cursorColor: context.color.primaryAccent,
                  obscureText: !_isConfirmPasswordVisible,
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    hintText: 'Nhập lại mật khẩu',
                    floatingLabelStyle: TextStyle(
                      color: context.color.primaryAccent,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: context.color.primaryAccent,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: context.color.primaryAccent,
                      ),
                    ),
                    suffix: GestureDetector(
                      onTap: _toggleConfirmPasswordVisibility,
                      child: Icon(
                        _isConfirmPasswordVisible
                            ? FontAwesomeIcons.eyeSlash
                            : FontAwesomeIcons.solidEye,
                        color: Colors.black26,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
                20.verticalSpace,
                Row(
                  children: [
                    Expanded(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: context.color.primaryAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                foregroundColor: Colors.white),
                            onPressed: _loading ? null : _register,
                            child: _loading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text("Hoàn tất đăng ký"))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
