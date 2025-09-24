// services/storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  // --- основные ключи авторизации ---
  static const _kLoggedIn   = 'isLoggedIn';
  static const _kMasterId   = 'userMasterId';
  static const _kUserName   = 'userName';
  static const _kUserPhone  = 'userPhone';
  static const _kAccess     = 'accessToken';
  static const _kRefresh    = 'refreshToken';

  // --- новые ключи для профиля ---
  static const _kProfileName   = 'user_name';   // локальное имя (для экрана профиля)
  static const _kUserAvatar    = 'user_avatar'; // локальный URL аватара

  /// Сохранить авторизацию
  Future<void> saveAuth({
    required int masterId,
    required String phone,
    required String name,
    String? access,
    String? refresh,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, true);
    await p.setInt(_kMasterId, masterId);
    await p.setString(_kUserPhone, phone);
    await p.setString(_kUserName, name);
    if (access != null) await p.setString(_kAccess, access);
    if (refresh != null) await p.setString(_kRefresh, refresh);
  }

  /// Очистить все данные пользователя
  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLoggedIn);
    await p.remove(_kMasterId);
    await p.remove(_kUserPhone);
    await p.remove(_kUserName);
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kProfileName);
    await p.remove(_kUserAvatar);
  }

  /// Проверка: залогинен ли пользователь
  Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) ?? false;
  }

  // --- геттеры авторизации ---
  Future<int?> get masterId async =>
      (await SharedPreferences.getInstance()).getInt(_kMasterId);

  Future<String?> get userName async =>
      (await SharedPreferences.getInstance()).getString(_kUserName);

  Future<String?> get userPhone async =>
      (await SharedPreferences.getInstance()).getString(_kUserPhone);

  Future<String?> get accessToken async =>
      (await SharedPreferences.getInstance()).getString(_kAccess);

  Future<String?> get refreshToken async =>
      (await SharedPreferences.getInstance()).getString(_kRefresh);

  // --- геттеры для локального профиля ---
  Future<String?> get profileName async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kProfileName);
  }

  Future<String?> get userAvatar async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUserAvatar);
  }

  // --- сеттеры для локального профиля ---
  Future<void> setProfileName(String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProfileName, value);
  }

  Future<void> setUserAvatar(String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserAvatar, value);
  }

  Future<void> setAccessToken(String value) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kAccess, value);
}

Future<void> clearAccessToken() async {
  final p = await SharedPreferences.getInstance();
  await p.remove(_kAccess);
}
}
