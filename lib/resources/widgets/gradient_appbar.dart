import 'package:flutter/material.dart';

class GradientAppBar extends AppBar {
  GradientAppBar({
    Key? key,
    required Widget title,
    Widget? leading,
    List<Widget>? actions,
  }) : super(
          key: key,
          title: title,
          leading: leading,
          actions: actions,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff179A6E), Color(0xff34B362)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        );
}
