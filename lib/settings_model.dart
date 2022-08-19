import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_model.dart';

/// Shared preference entries:
/// - languageCode: nullable non-empty String
/// - countryCode: nullable non-empty String
/// - enableLocation: nullable bool
enum SPKeys { languageCode, countryCode, enableLocation }

class SettingsModel extends ChangeNotifier {
  final BuildContext _context;

  Locale? locale;
  bool? enableLocation;

  SettingsModel(BuildContext context) : _context = context;

  /// Load initial settings from shared preferences
  Future<void> initSettings() async {
    final prefs = await SharedPreferences.getInstance();

    var languageCode = prefs.getString(SPKeys.languageCode.name);
    if (languageCode != null) {
      var countryCode = prefs.getString(SPKeys.countryCode.name);
      locale = Locale(languageCode, countryCode);
    }

    var locSetting = prefs.getBool(SPKeys.enableLocation.name);
    if (locSetting ?? false) {
      // location is enabled, but we need to check permission.
      var provider = Provider.of<LocationModel>(_context, listen: false);
      var locAvailable = await provider.checkLocationPermission();
      if (!locAvailable) {
        // If denied, automatically turn this off
        locSetting = false;
        // TODO: Should we also change the value in shared preference?
      }
    }
    enableLocation = locSetting;

    notifyListeners();
  }

  Future<void> setEnableLocation(bool enabled) async {
    enableLocation = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SPKeys.enableLocation.name, enabled);
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    this.locale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString(SPKeys.languageCode.name, locale.languageCode);
      var countryCode = locale.countryCode;
      if (countryCode != null) {
        await prefs.setString(SPKeys.countryCode.name, countryCode);
      }
    } else {
      await prefs.remove(SPKeys.languageCode.name);
      await prefs.remove(SPKeys.countryCode.name);
    }
    notifyListeners();
  }
}
