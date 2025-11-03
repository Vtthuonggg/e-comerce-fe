import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/models/user.dart';
import 'package:flutter_app/resources/pages/employee/list_emplopyee_page.dart';
import 'package:flutter_app/resources/pages/main_page.dart';
import 'package:nylo_framework/nylo_framework.dart';

enum DashboardItem {
  Table,
  OrderList,
  OrderPurchase,
  OrderSale,
  Service,
  Storage,
  CashBook,
  Employee,
  Customer,
  Supplier,
  Report,
  TimekeepingCreate,
}

extension DashboardItemExtension on DashboardItem {
  String get name {
    switch (this) {
      case DashboardItem.Table:
        return 'Bàn';
      case DashboardItem.OrderList:
        return 'Đơn hàng';
      case DashboardItem.OrderPurchase:
        return 'Nhập hàng';
      case DashboardItem.OrderSale:
        return 'Bán hàng';
      case DashboardItem.Service:
        return 'Dịch vụ';
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

      case DashboardItem.TimekeepingCreate:
        return 'Chấm công';
      default:
        return '';
    }
  }

  dynamic get icon {
    switch (this) {
      case DashboardItem.Table:
        return Icons.table_restaurant; // Icon bàn nhà hàng
      case DashboardItem.OrderList:
        return Icons.list_alt; // Icon danh sách đơn hàng
      case DashboardItem.OrderPurchase:
        return Icons.local_shipping; // Icon nhập hàng
      case DashboardItem.OrderSale:
        return Icons.point_of_sale; // Icon bán hàng/thu ngân
      case DashboardItem.Service:
        return Icons.restaurant_menu; // Icon dịch vụ nhà hàng
      case DashboardItem.Storage:
        return Icons.inventory; // Icon kho
      case DashboardItem.CashBook:
        return Icons.account_balance_wallet; // Icon sổ quỹ
      case DashboardItem.Employee:
        return Icons.people; // Icon nhân viên
      case DashboardItem.Customer:
        return Icons.group; // Icon khách hàng
      case DashboardItem.Supplier:
        return Icons.business; // Icon nhà cung cấp
      case DashboardItem.Report:
        return Icons.analytics; // Icon báo cáo
      case DashboardItem.TimekeepingCreate:
        return Icons.access_time; // Icon chấm công
      default:
        return Icons.help_outline;
    }
  }

  String? get routePath {
    switch (this) {
      case DashboardItem.Table:
        return MainPage.path;
      case DashboardItem.OrderList:
        return MainPage.path;
      case DashboardItem.OrderPurchase:
        return MainPage.path;
      case DashboardItem.OrderSale:
        return MainPage.path;
      case DashboardItem.Service:
        return MainPage.path;
      case DashboardItem.Storage:
        return MainPage.path;
      case DashboardItem.CashBook:
        return MainPage.path;
      case DashboardItem.Employee:
        return ListEmployeePage.path;
      case DashboardItem.Customer:
        return MainPage.path;
      case DashboardItem.Supplier:
        return MainPage.path;
      case DashboardItem.Report:
        return MainPage.path;
      case DashboardItem.TimekeepingCreate:
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
        DashboardItem.Table,
        DashboardItem.OrderList,
        DashboardItem.OrderSale,
        DashboardItem.Service,
        DashboardItem.Storage,
        DashboardItem.CashBook,
        DashboardItem.Employee,
        DashboardItem.Customer,
        DashboardItem.Supplier,
        DashboardItem.Report,
      ];
    case 3:
      return [
        DashboardItem.Table,
        DashboardItem.OrderList,
        DashboardItem.OrderSale,
        DashboardItem.Service,
        DashboardItem.Storage,
        DashboardItem.CashBook,
        DashboardItem.Employee,
        DashboardItem.Customer,
        DashboardItem.Supplier,
        DashboardItem.Report,
        DashboardItem.TimekeepingCreate,
      ];
    default:
      return [];
  }
}
