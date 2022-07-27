import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel extends ChangeNotifier {
  /* Shared preference entries:
   * languageCode: nullable non-empty String
   * countryCode: nullable non-empty String
   */

  Locale? locale;

  /// Load initial locale from shared preferences
  Future<void> initLocale() async {
    final prefs = await SharedPreferences.getInstance();
    var languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      var countryCode = prefs.getString('countryCode');
      locale = Locale(languageCode, countryCode);
      notifyListeners();
    }
  }

  /// Set new locale and save the settings to preferences
  Future<void> setLocale(Locale? locale) async {
    this.locale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString('languageCode', locale.languageCode);
      var countryCode = locale.countryCode;
      if (countryCode != null) {
        await prefs.setString('countryCode', countryCode);
      }
    } else {
      await prefs.remove('languageCode');
      await prefs.remove('countryCode');
    }
    notifyListeners();
  }
}
