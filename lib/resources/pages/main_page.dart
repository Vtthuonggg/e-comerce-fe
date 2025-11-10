// lib/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/config/common_define.dart';
import 'package:flutter_app/resources/pages/dash_board_page.dart';
import 'package:flutter_app/resources/pages/order/order_list_all_page.dart';
import 'package:flutter_app/resources/pages/product/list_product_page.dart';
import 'package:flutter_app/resources/pages/setting_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';

enum ScreenTab { SCREEN_HOME, SCREEN_ORDERS, SCREEN_PRODUCTS, SCREEN_ACCOUNT }

extension ScreenTabExt on ScreenTab {
  int get position {
    switch (this) {
      case ScreenTab.SCREEN_HOME:
        return 0;
      case ScreenTab.SCREEN_ORDERS:
        return 1;
      case ScreenTab.SCREEN_PRODUCTS:
        return 2;
      case ScreenTab.SCREEN_ACCOUNT:
        return 3;
    }
  }
}

class MainPage extends StatefulWidget {
  static const path = '/main_page';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _mainScaffoldKey = GlobalKey<ScaffoldState>();
  final PersistentTabController _tabController =
      PersistentTabController(initialIndex: 0);
  int prePosition = 0;
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _accountNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _productNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _orderNavKey = GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState>? _currentGlobalKey() {
    if (prePosition == ScreenTab.SCREEN_HOME.position) {
      return _homeNavKey;
    }
    if (prePosition == ScreenTab.SCREEN_ACCOUNT.position) {
      return _accountNavKey;
    }
    if (prePosition == ScreenTab.SCREEN_PRODUCTS.position) {
      return _productNavKey;
    }
    if (prePosition == ScreenTab.SCREEN_ORDERS.position) {
      return _orderNavKey;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _mainScaffoldKey,
        body: PersistentTabView(context,
            controller: _tabController,
            screens: _buildScreens(),
            items: _navBarsItems(),
            confineInSafeArea: true,
            backgroundColor: Colors.white,
            handleAndroidBackButtonPress: true,
            resizeToAvoidBottomInset: true,
            stateManagement: true,
            selectedTabScreenContext: (context) {},
            hideNavigationBarWhenKeyboardShows: true,
            decoration: NavBarDecoration(
                borderRadius: BorderRadius.zero,
                colorBehindNavBar: ThemeColor.get(context).primaryAccent,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ]),
            popAllScreensOnTapOfSelectedTab: true,
            popActionScreens: PopActionScreensType.all,
            onWillPop: (context) async {
          if (_currentIndex == prePosition) {
            GlobalKey<NavigatorState>? currentKey = _currentGlobalKey();
            if (currentKey != null) {
              if (await currentKey.currentState?.maybePop() != true) {
                tabController?.jumpToTab(_currentIndex);
              }
            }
          }
          return true;
        }, navBarHeight: 60.0, navBarStyle: NavBarStyle.style6));
  }

  List<Widget> _buildScreens() {
    return [
      DashboardPage(key: _homeNavKey),
      OrderListAllPage(key: _orderNavKey),
      ListProductPage(key: _productNavKey),
      SettingPage(
        key: _accountNavKey,
      ),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    Color activeColor = ThemeColor.get(context).primaryAccent;
    Color inactiveColor = Color(0XFF9DAF99);
    return [
      PersistentBottomNavBarItem(
          title: 'Trang chủ',
          icon: Icon(
            IconlyLight.home,
            color: activeColor,
          ),
          inactiveIcon: Icon(
            IconlyLight.home,
            color: inactiveColor,
          ),
          activeColorPrimary: activeColor,
          inactiveColorPrimary: inactiveColor,
          textStyle: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      PersistentBottomNavBarItem(
          title: 'Đơn hàng',
          icon: Icon(IconsaxPlusLinear.task, color: activeColor),
          inactiveIcon: Icon(
            IconsaxPlusLinear.task,
            color: inactiveColor,
          ),
          activeColorPrimary: activeColor,
          inactiveColorPrimary: inactiveColor,
          textStyle: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      PersistentBottomNavBarItem(
          title: 'Món ăn',
          icon: Icon(
            FontAwesomeIcons.store,
            color: activeColor,
            size: 25,
          ),
          inactiveIcon: Icon(
            FontAwesomeIcons.store,
            color: inactiveColor,
            size: 22,
          ),
          activeColorPrimary: activeColor,
          inactiveColorPrimary: inactiveColor,
          textStyle: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      PersistentBottomNavBarItem(
          title: 'Cài đặt',
          icon: Icon(
            IconsaxPlusLinear.setting_2,
            color: activeColor,
            size: 25,
          ),
          inactiveIcon: Icon(
            IconsaxPlusLinear.setting_2,
            color: inactiveColor,
            size: 22,
          ),
          activeColorPrimary: activeColor,
          inactiveColorPrimary: inactiveColor,
          textStyle: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    ];
  }
}
