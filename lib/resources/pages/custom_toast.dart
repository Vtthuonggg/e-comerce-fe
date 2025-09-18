import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  static bool _isShowing = false;
  static void showToast(
    BuildContext context,
    String message, {
    IconData? icon,
    ToastGravity gravity = ToastGravity.TOP,
    Color backgroundColor = const Color.fromRGBO(255, 255, 255, 1),
    Color textColor = Colors.black,
    Color iconColor = Colors.black,
    double fontSize = 16.0,
    Duration duration = const Duration(milliseconds: 1200),
    Color borderColor = Colors.transparent,
  }) {
    if (_isShowing) return;

    _isShowing = true;
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        left: 0,
        right: 0,
        child: Center(
          child: IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 20.0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: iconColor),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 800),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                                child: child, scale: animation);
                          },
                          child: Text(
                            message,
                            style: TextStyle(
                              color: textColor,
                              fontSize: fontSize,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
      _isShowing = false;
    });
  }

  static void _showToast(
      BuildContext context, String message, Color color, IconData icon) {
    if (!context.mounted) return; // Context safety check

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showToastSuccess(BuildContext context,
      {required String description}) {
    showToast(
      context,
      description,
      textColor: Colors.white,
      icon: Icons.check_circle_outline_rounded,
      iconColor: Colors.white,
      backgroundColor: Color(0xFF4CAF50), // Material Green
    );
  }

  static void showToastInfo(BuildContext context,
      {required String description}) {
    showToast(
      context,
      description,
      textColor: Colors.white,
      icon: Icons.info_outline_rounded,
      iconColor: Colors.white,
      backgroundColor: Color(0xFF2196F3), // Material Blue
    );
  }

  static void showToastError(BuildContext context,
      {required String description}) {
    showToast(
      context,
      description,
      textColor: Colors.white,
      icon: Icons.error_outline_rounded,
      iconColor: Colors.white,
      backgroundColor: Color(0xFFEB5757), // Red
    );
  }

  static void showToastWarning(BuildContext context,
      {required String description}) {
    showToast(
      context,
      description,
      textColor: Colors.white,
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.white,
      backgroundColor: Color(0xFFFF9800), // Material Orange
    );
  }
}

/// A customizable UnderlineRow widget with adjustable border width.
///
/// [borderWidth] mặc định là 2.0 nhưng có thể được điều chỉnh khi khởi tạo.
/// Bạn cũng có thể tùy chỉnh màu sắc của đường viền nếu muốn.
class UnderlineRow extends StatelessWidget {
  final double borderWidth; // Mặc định là 2.0
  final Color firstBorderColor;
  final Color secondBorderColor;

  const UnderlineRow({
    Key? key,
    this.borderWidth = 2.0, // Giá trị mặc định
    this.firstBorderColor = Colors.black,
    this.secondBorderColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: Row(
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border(
                bottom: BorderSide(
                  color: firstBorderColor.withOpacity(0.8),
                  width: borderWidth,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: secondBorderColor.withOpacity(0.2),
                    width: borderWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
