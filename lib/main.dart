import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/bootstrap/app.dart';
import 'package:flutter_app/bootstrap/boot.dart';
import 'package:flutter_app/config/storage_keys.dart';
import 'package:flutter_app/login_page.dart';
import 'package:flutter_app/resources/pages/main_page.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:nylo_framework/nylo_framework.dart';

void main() async {
  Nylo.init();
  Nylo nylo = await Nylo.init(setup: Boot.nylo, setupFinished: Boot.finished);

  initializeDateFormatting('vi_VN').then((_) => runApp(AppBuild(
        navigatorKey: NyNavigator.instance.router.navigatorKey,
        onGenerateRoute: nylo.router!.generator(),
        debugShowCheckedModeBanner: false,
        initialRoute: SplashScreen.path,
        themeData: ThemeData(
          brightness: Brightness.light,
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
          ),
        ),
      )));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const path = '/splash_screen';
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserToken();
  }

  void _checkUserToken() async {
    String? userToken = await NyStorage.read(StorageKey.userToken);
    // if (userToken != null) {
    //   routeTo(MainScreen.path, navigationType: NavigationType.pushReplace);
    // } else {
    routeTo(LoginPage.path, navigationType: NavigationType.pushReplace);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
              scale: 0.5, child: Image.asset('public/assets/images/bate.png')),
          CircularProgressIndicator(
            color: Colors.blue,
          )
        ],
      ),
    );
  }
}
