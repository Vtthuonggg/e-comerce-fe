import 'package:flutter_app/resources/pages/main_page.dart';
import 'package:nylo_framework/nylo_framework.dart';

class LoginEvent implements NyEvent {
  @override
  final listeners = {
    DefaultListener: DefaultListener(),
  };
}

class DefaultListener extends NyListener {
  @override
  handle(dynamic event) async {
    await Auth.set(event['user']);
    routeTo(MainPage.path, navigationType: NavigationType.pushReplace);
  }
}
