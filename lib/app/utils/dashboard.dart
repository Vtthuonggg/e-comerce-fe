import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/resources/pages/customer/list_customer_page.dart';
import 'package:flutter_app/resources/pages/ingredient/list_ingredient_page.dart';
import 'package:flutter_app/resources/pages/employee/list_emplopyee_page.dart';
import 'package:flutter_app/resources/pages/main_page.dart';
import 'package:flutter_app/resources/pages/order/order_list_all_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:nylo_framework/nylo_framework.dart';

enum DashboardItem {
  Service,
  Product,
  Storage,
  CashBook,
  Employee,
  Customer,
  Supplier,
  Ingredient,
  Plus,
}

extension DashboardItemExtension on DashboardItem {
  String get name {
    switch (this) {
      case DashboardItem.Ingredient:
        return 'Nguyên Liệu';
      case DashboardItem.Storage:
        return 'Kho';
      case DashboardItem.CashBook:
        return 'Sổ quỹ';
      case DashboardItem.Employee:
        return 'Nhân viên';
      case DashboardItem.Customer:
        return 'Khách hàng';
      case DashboardItem.Supplier:
        return 'Nhà cung cấp';

      default:
        return '';
    }
  }

  dynamic get icon {
    switch (this) {
      case DashboardItem.Service:
        return IconsaxPlusLinear.receipt_1; // store

      case DashboardItem.Storage:
        return IconsaxPlusLinear.archive;
      case DashboardItem.CashBook:
        return IconsaxPlusLinear.convert_card;
      case DashboardItem.Employee:
        return IconsaxPlusLinear.tag_user;
      case DashboardItem.Customer:
        return IconsaxPlusLinear.people;
      case DashboardItem.Supplier:
        return IconsaxPlusLinear.user_octagon;

      case DashboardItem.Plus:
        return IconlyLight.plus;
      case DashboardItem.Product:
        return Icons.inventory_2_outlined;
      default:
        return IconsaxPlusLinear.home_2;
    }
  }

  String? get routePath {
    switch (this) {
      case DashboardItem.Ingredient:
        return ListIngredientPage.path;
      case DashboardItem.Storage:
        return MainPage.path;
      case DashboardItem.CashBook:
        return MainPage.path;
      case DashboardItem.Employee:
        return MainPage.path;
      case DashboardItem.Customer:
        return ListCustomerPage.path;
      case DashboardItem.Supplier:
        return MainPage.path;

      default:
        return null;
    }
  }
}

List<DashboardItem> getDashboardItems() {
  int? userType = Auth.user<User>()?.type;
  switch (userType) {
    case 2:
      return [
        DashboardItem.Ingredient,
        DashboardItem.Storage,
        DashboardItem.CashBook,
        DashboardItem.Employee,
        DashboardItem.Customer,
        DashboardItem.Supplier,
      ];
    case 3:
      return [
        DashboardItem.Ingredient,
        DashboardItem.Storage,
        DashboardItem.CashBook,
        DashboardItem.Employee,
        DashboardItem.Customer,
        DashboardItem.Supplier,
      ];
    default:
      return [];
  }
}
