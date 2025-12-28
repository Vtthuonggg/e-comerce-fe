import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/resources/pages/category/list_category_page.dart';
import 'package:flutter_app/resources/pages/customer/list_customer_page.dart';
import 'package:flutter_app/resources/pages/ingredient/list_ingredient_page.dart';
import 'package:flutter_app/resources/pages/employee/list_emplopyee_page.dart';
import 'package:flutter_app/resources/pages/main_page.dart';
import 'package:flutter_app/resources/pages/supplier/list_supplier_page.dart';
import 'package:flutter_app/resources/themes/styles/color_styles.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:nylo_framework/nylo_framework.dart';

enum DashboardItem {
  Report,
  Storage,
  CashBook,
  Employee,
  Customer,
  Supplier,
  Ingredient,
  Category,
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
      case DashboardItem.Report:
        return 'Báo cáo';
      case DashboardItem.Category:
        return 'Danh mục';

      default:
        return '';
    }
  }

  Color get color {
    switch (this) {
      case DashboardItem.Ingredient:
        return HexColor.fromHex('#4C99EA');
      case DashboardItem.Report:
        return HexColor.fromHex('#F5A524');
      case DashboardItem.Storage:
        return HexColor.fromHex('#E0845E');
      case DashboardItem.CashBook:
        return HexColor.fromHex('#70CD55');
      case DashboardItem.Employee:
        return HexColor.fromHex('#89A5FE');
      case DashboardItem.Customer:
        return HexColor.fromHex('#D5B3FE');
      case DashboardItem.Supplier:
        return HexColor.fromHex('#11CDFB');
      case DashboardItem.Category:
        return HexColor.fromHex('#9C27B0');

      default:
        return Colors.blueGrey;
    }
  }

  dynamic get icon {
    switch (this) {
      case DashboardItem.Report:
        return IconsaxPlusLinear.status_up; // store
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
      case DashboardItem.Ingredient:
        return Icons.inventory_2_outlined;
      case DashboardItem.Category:
        return IconsaxPlusLinear.category;
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
        return ListEmployeePage.path;
      case DashboardItem.Customer:
        return ListCustomerPage.path;
      case DashboardItem.Supplier:
        return ListSupplierPage.path;
      case DashboardItem.Report:
        return MainPage.path;
      case DashboardItem.Category:
        return ListCategoryPage.path;
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
        DashboardItem.Category,
        DashboardItem.Report,
      ];
    case 3:
      return [
        DashboardItem.Ingredient,
        DashboardItem.Storage,
        DashboardItem.CashBook,
        DashboardItem.Customer,
        DashboardItem.Supplier,
        DashboardItem.Category,
        DashboardItem.Report,
      ];
    default:
      return [];
  }
}
