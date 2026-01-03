import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoading extends StatelessWidget {
  final double size;
  final String? text;
  final Color? backgroundColor;

  const AppLoading({
    super.key,
    this.size = 120,
    this.text,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lottie/loading.json',
            width: size,
            height: size,
            repeat: true,
          ),
          if (text != null) ...[
            const SizedBox(height: 12),
            Text(
              text!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
