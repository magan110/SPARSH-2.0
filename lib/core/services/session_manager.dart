import 'package:shared_preferences/shared_preferences.dart';

/// Simple session accessor for values saved by LoginScreen
/// Keys used in login_screen.dart: 'userID', 'areaCode', 'emplName', 'roles', 'isLoggedIn'
class SessionManager {
  static String? _loginId;
  static String? _areaCode;
  static String? _emplName;

  /// Loads values from SharedPreferences into memory cache.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loginId = prefs.getString('userID');
    _areaCode = prefs.getString('areaCode');
    _emplName = prefs.getString('emplName');
  }

  static Future<String?> getLoginId() async {
    if (_loginId != null) return _loginId;
    await init();
    return _loginId;
  }

  static Future<String?> getAreaCode() async {
    if (_areaCode != null) return _areaCode;
    await init();
    return _areaCode;
  }

  static Future<String?> getEmplName() async {
    if (_emplName != null) return _emplName;
    await init();
    return _emplName;
  }
}
