import 'package:flutter/material.dart';
import 'package:flutter_app/app/controllers/controller.dart';
import 'package:flutter_app/app/networking/account_api.dart';
import 'package:flutter_app/app/utils/message.dart';
import 'package:flutter_app/bootstrap/extensions.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/resources/pages/custom_toast.dart';
import 'package:flutter_app/resources/widgets/gradient_appbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:flutter_app/resources/pages/register_otp_page.dart';

class RegisterPage extends NyStatefulWidget {
  final Controller controller = Controller();
  static const path = '/register_page';

  RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends NyState<RegisterPage> {
  bool _loading = false;
  String _errorMessage = '';
  TextEditingController _emailController = TextEditingController();

  _sendOtp() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      await api<AccountApi>(
          (request) => request.sendOtp(_emailController.text));
      CustomToast.showToastSuccess(context, description: "Đã gửi mã OTP");
      routeTo(RegisterOtpPage.path, data: {'email': _emailController.text});
    } catch (e) {
      setState(() {
        _errorMessage = getResponseError(e);
      });
      CustomToast.showToastError(context, description: _errorMessage);
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
        title: Text('Đăng ký'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.verticalSpace,
              Text(
                'Nhập email của bạn',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.color.primaryAccent),
              ),
              12.verticalSpace,
              Text(
                'Chúng tôi sẽ gửi mã OTP để xác thực email của bạn',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              20.verticalSpace,
              TextField(
                controller: _emailController,
                cursorColor: context.color.primaryAccent,
                keyboardType: TextInputType.emailAddress,
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
                          onPressed: _loading ? null : _sendOtp,
                          child: _loading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("Tiếp tục"))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
