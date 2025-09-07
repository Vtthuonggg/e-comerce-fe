import 'package:flutter_app/login_page.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/register_page.dart';
import 'package:flutter_app/resources/pages/dash_board_page.dart';
import 'package:flutter_app/resources/pages/main_page.dart';
import 'package:flutter_app/resources/pages/product/edit_product_page.dart';
import 'package:flutter_app/resources/pages/product/list_product_page.dart';
import 'package:flutter_app/resources/pages/setting/info_account_setting_page.dart';
import 'package:flutter_app/resources/pages/setting_page.dart';

import 'package:nylo_framework/nylo_framework.dart';

/* App Router
|--------------------------------------------------------------------------
| * [Tip] Create pages faster 🚀
| Run the below in the terminal to create new a page.
| "dart run nylo_framework:main make:page profile_page"
| Learn more https://nylo.dev/docs/5.20.0/router
|-------------------------------------------------------------------------- */

appRouter() => nyRoutes((router) {
      router.route(
        MainPage.path,
        (context) => MainPage(),
        transition: PageTransitionType.rightToLeft,
        pageTransitionSettings: const PageTransitionSettings(),
      );
      router.route(
        DashboardPage.path,
        (context) => DashboardPage(),
        transition: PageTransitionType.rightToLeft,
        pageTransitionSettings: const PageTransitionSettings(),
      );
      router.route(
        LoginPage.path,
        (context) => LoginPage(),
        transition: PageTransitionType.bottomToTop,
        pageTransitionSettings: const PageTransitionSettings(),
      );
      router.route(
        SplashScreen.path,
        (context) => SplashScreen(),
        transition: PageTransitionType.bottomToTop,
        pageTransitionSettings: const PageTransitionSettings(),
      );
      router.route(
        RegisterPage.path,
        (context) => RegisterPage(),
        transition: PageTransitionType.rightToLeft,
        pageTransitionSettings: const PageTransitionSettings(),
      );
      router.route(
        SettingPage.path,
        (context) => SettingPage(),
        transition: PageTransitionType.rightToLeft,
        pageTransitionSettings: const PageTransitionSettings(),
      );
      router.route(
        InfoSettingPage.path,
        (context) => InfoSettingPage(),
        transition: PageTransitionType.rightToLeft,
        pageTransitionSettings: const PageTransitionSettings(),
      );
      router.route(
        ListProductPage.path,
        (context) => ListProductPage(),
        transition: PageTransitionType.rightToLeft,
        pageTransitionSettings: const PageTransitionSettings(),
      );
      router.route(
        EditProductPage.path,
        (context) => EditProductPage(),
        transition: PageTransitionType.rightToLeft,
        pageTransitionSettings: const PageTransitionSettings(),
      );
    });
