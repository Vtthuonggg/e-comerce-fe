import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/networking/account_api.dart';
import 'package:flutter_app/bootstrap/extensions.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nylo_framework/nylo_framework.dart';

class RegisterPage extends NyStatefulWidget {
  final Controller controller = Controller();

  static const path = '/register_page';
  RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends NyState<RegisterPage> {
  bool _loading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  _register() async {
    if (_phoneController.text == '' || _passwordController.text == '') {
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
    });
    final payload = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'password': _passwordController.text,
      'user_type': 2,
    };

    try {
      await api<AccountApi>((request) => request.register(payload));
      CustomToast.showToastSuccess(context, description: "Đăng ký thành công");
      Navigator.of(context).pop();
    } catch (e) {
      CustomToast.showToastWarning(context, description: "Đăng ký thất bại");
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
        title: Text(''),
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
                'Đăng nhập',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: context.color.primaryAccent),
              ),
              12.verticalSpace,
              TextField(
                controller: _nameController,
                cursorColor: context.color.primaryAccent,
                onTapOutside: (event) {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                    labelText: 'Tên người dùng',
                    hintText: 'Nhập tên người dùng',
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
              TextField(
                controller: _phoneController,
                cursorColor: context.color.primaryAccent,
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
                obscureText: !_isPasswordVisible,
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
              SizedBox(height: 20),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
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
                          onPressed: () {
                            _register();
                          },
                          child: _loading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text("Đăng ký"))),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }
}
