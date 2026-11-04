// App settings service: app version, developer contact.
// Persisted in SharedPreferences so choices survive restarts.

import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _fontScaleKey = 'app_font_scale'; // double string
  static const String _version = '1.0.0+1';
  static const String _developerName = 'VoiceHealth Care Team';
  static const String _developerEmail = 'tonnychibambo@gmail.com';
  static const String _developerPhone = '+265888081368';

  double _fontScale = 1.0;

  double get fontScale => _fontScale;
  String get version => _version;
  String get developerName => _developerName;
  String get developerEmail => _developerEmail;
  String get developerPhone => _developerPhone;

  // Load saved settings once at app start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    if (_fontScale < 0.8) _fontScale = 0.8;
    if (_fontScale > 2.0) _fontScale = 2.0;
  }

  // Save font scale choice.
  Future<void> setFontScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
    _fontScale = scale;
  }
}
