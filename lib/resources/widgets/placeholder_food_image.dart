import 'package:flutter/material.dart';

class PlaceholderFoodImage extends StatelessWidget {
  final double width;
  final double height;
  final double iconSize;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;

  const PlaceholderFoodImage({
    Key? key,
    this.width = 80,
    this.height = 80,
    this.iconSize = 32,
    this.icon = Icons.fastfood_outlined,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: backgroundColor ?? Colors.grey.shade100,
      ),
      child: Icon(
        icon,
        color: iconColor ?? Colors.grey.shade400,
        size: iconSize,
      ),
    );
  }
}
