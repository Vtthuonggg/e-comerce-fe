import 'package:flutter/material.dart';
import 'package:flutter_app/app/networking/account_api.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import '../main.dart';

GlobalKey<ScaffoldState>? mainScaffoldKey;
PersistentTabController? tabController;

final AccountApi userApiService = AccountApi();
// Future<void> getFCMTokenAndSave() async {
//   try {
//     final token = await FCMService.getFCMToken();
//     if (token != null) {
//       await userApiService.saveDeviceToken(token);
//       print("save fcmToken success");
//     }
//   } catch (e) {
//     print('Error while getting FCM Token: $e');
//   }
// }

MaterialColor createColor(Color color) {
  Map<int, Color> swatch = {
    50: color.withOpacity(.1),
    100: color.withOpacity(.2),
    200: color.withOpacity(.3),
    300: color.withOpacity(.4),
    400: color.withOpacity(.5),
    500: color.withOpacity(.6),
    600: color.withOpacity(.7),
    700: color.withOpacity(.8),
    800: color.withOpacity(.9),
    900: color.withOpacity(1),
  };

  return MaterialColor(color.value, swatch);
}

void gotoTabPage(int page) {
  if (page >= 0 && page < 4) {
    tabController?.jumpToTab(page);
  }
}
