import 'package:flutter_app/config/common_define.dart';
import 'package:flutter_app/config/storage_keys.dart';
import 'package:flutter_app/resources/pages/login_page.dart';
import 'package:nylo_framework/nylo_framework.dart';

class LogoutEvent implements NyEvent {
  @override
  final listeners = {
    DefaultListener: DefaultListener(),
  };
}

class DefaultListener extends NyListener {
  @override
  handle(dynamic event) async {
    await Auth.remove();
    NyStorage.delete(StorageKey.userToken, andFromBackpack: true);
    mainScaffoldKey = null;
    routeTo(LoginPage.path, navigationType: NavigationType.pushReplace);
  }
}
