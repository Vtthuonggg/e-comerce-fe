import 'dart:async';
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
import 'package:flutter_app/resources/pages/register_info_page.dart';

class RegisterOtpPage extends NyStatefulWidget {
  final Controller controller = Controller();
  static const path = '/register_otp_page';

  RegisterOtpPage({Key? key}) : super(key: key);

  @override
  State<RegisterOtpPage> createState() => _RegisterOtpPageState();
}

class _RegisterOtpPageState extends NyState<RegisterOtpPage> {
  bool _loading = false;
  String _errorMessage = '';
  List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 120;
  Timer? _timer;
  String? email;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      email = widget.data()['email'] as String?;
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 120;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _timerText {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _verifyOtp() async {
    String otp = _getOtpCode();
    if (otp.length != 6) return;

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      await api<AccountApi>((request) => request.verifyOtp(email!, otp));
      CustomToast.showToastSuccess(context, description: "Xác thực thành công");
      routeTo(RegisterInfoPage.path, data: {'email': email, 'otp': otp});
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

  Future<void> _resendOtp() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      await api<AccountApi>((request) => request.resendOtp(email!));
      CustomToast.showToastSuccess(context, description: "Đã gửi lại mã OTP");
      _startTimer();
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
        title: Text('Xác thực OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.verticalSpace,
              Text(
                'Nhập mã OTP',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.color.primaryAccent),
              ),
              12.verticalSpace,
              Text(
                'Mã OTP đã được gửi đến $email',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              30.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: context.color.primaryAccent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: context.color.primaryAccent, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        // Auto verify when all 6 digits entered
                        if (index == 5 && value.isNotEmpty) {
                          _verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ),
              20.verticalSpace,
              Center(
                child: Text(
                  _secondsRemaining > 0
                      ? 'Mã hết hạn sau: $_timerText'
                      : 'Mã đã hết hạn',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
              if (_secondsRemaining == 0)
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
                        onPressed: _loading ? null : _resendOtp,
                        child: _loading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Gửi lại mã"),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
