import 'package:flutter_app/bootstrap/helpers.dart';
import 'package:flutter_app/config/storage_keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

class AuthProvider implements NyProvider {
  @override
  boot(Nylo nylo) async {
    await event<SyncAuthToBackpackEvent>();
    return nylo;
  }

  @override
  afterBoot(Nylo nylo) async {
    String? token = await NyStorage.read(StorageKey.userToken);
    if (token != null) {
      Backpack.instance.set(StorageKey.userToken, token);
    }
  }
}
