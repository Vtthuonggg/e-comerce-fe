import 'dart:developer';
import 'dart:io';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/app_loading.dart';
import 'package:nylo_framework/nylo_framework.dart';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/events/login_event.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/app/networking/account_api.dart';
import 'package:flutter_app/bootstrap/extensions.dart';
import 'package:flutter_app/resources/pages/register_page.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../bootstrap/helpers.dart';

class LoginPage extends NyStatefulWidget {
  final Controller controller = Controller();

  static const path = '/login_page';

  LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends NyState<LoginPage> {
  bool _loading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  int userType = 2;
  _login() async {
    if (_emailController.text == '' || _passwordController.text == '') {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }
    try {
      // nếu bạn dùng host khác, đổi '192.168.1.10' thành host tương ứng
      final result = await InternetAddress.lookup('192.168.1.10');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        setState(() {
          _errorMessage = 'Không thể kết nối tới server';
        });
        CustomToast.showToastError(context, description: _errorMessage);
        return;
      }
    } on SocketException catch (_) {
      setState(() {
        _errorMessage =
            'Không có kết nối mạng đến server. Kiểm tra Wi-Fi / firewall / permission.';
      });
      CustomToast.showToastError(context, description: _errorMessage);
      return;
    }
    _errorMessage = '';
    setState(() {
      _loading = true;
    });
    final payload = {
      'username': _emailController.text,
      'password': _passwordController.text,
      'is_employee': userType == 1 ? true : false,
    };

    try {
      User user = await api<AccountApi>((request) => request.login(payload));
      event<LoginEvent>(data: {
        'user': user,
      });
      CustomToast.showToastSuccess(context,
          description: "Đăng nhập thành công");
    } catch (e) {
      setState(() {
        _errorMessage = getResponseError(e);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

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
                controller: _emailController,
                cursorColor: context.color.primaryAccent,
                onTapOutside: (event) {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'VD: user@example.com',
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
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ],
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    child: Text(
                      'Quên mật khẩu',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  Row(
                    children: [
                      Text('Bạn là nhân viên'),
                      Checkbox(
                          activeColor: ThemeColor.get(context).primaryAccent,
                          value: userType == 1,
                          onChanged: (value) {
                            setState(() {
                              userType = value! ? 1 : 2;
                            });
                          })
                    ],
                  )
                ],
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
                            _login();
                          },
                          child: _loading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text("Đăng nhập"))),
                ],
              ),
              8.verticalSpace,
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    color: context.color.primaryAccent),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              foregroundColor: context.color.primaryAccent),
                          onPressed: () {
                            routeTo(RegisterPage.path);
                          },
                          child: Text("Đăng ký"))),
                ],
              )
            ],
          ),
        ),
      )),
    );
  }
}
