import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'about_page.dart';
import 'settings_model.dart';
import 'location_model.dart';

class OthersPage extends StatefulWidget {
  const OthersPage({Key? key}) : super(key: key);

  @override
  _OthersPageState createState() => _OthersPageState();
}

class _OthersPageState extends State<OthersPage> {
  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(title: Text(appLocalizations.others)),
        body: ListView(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  appLocalizations.settings,
                  style: Theme.of(context).textTheme.caption,
                )),
            Consumer<SettingsModel>(
              builder: (context, settingsModel, child) {
                return ListTile(
                  title: Text(appLocalizations.language),
                  subtitle: Text(
                      LocaleUtil.locale2String(settingsModel.locale) ??
                          appLocalizations.systemLanguage),
                  trailing: const Icon(Icons.navigate_next),
                  onTap: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LanguagePage(
                                    selected: settingsModel.locale)))
                        .then((localeKey) {
                      if (localeKey != null) {
                        settingsModel
                            .setLocale(LocaleUtil.key2Locale(localeKey));
                      }
                    });
                  },
                );
              },
            ),
            Consumer<SettingsModel>(
              builder: (context, settingsModel, child) {
                return CheckboxListTile(
                  title: Text(appLocalizations.location),
                  subtitle: Text(appLocalizations.locationDesp),
                  value: settingsModel.enableLocation ?? false,
                  onChanged: (v) async {
                    var provider =
                        Provider.of<LocationModel>(context, listen: false);
                    if (v ?? false) {
                      // Try to turn on location
                      var locAvailable =
                          await provider.checkLocationPermission();
                      if (!locAvailable) {
                        // Failed to enable location, e.g. because user rejects the request
                        var snackBar = SnackBar(
                          content: Text(appLocalizations.locationPermissionErr),
                          duration: const Duration(seconds: 5),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        v = false;
                      }
                    }
                    settingsModel.setEnableLocation(v ?? false);
                    if (v ?? false) {
                      provider.registerLocUpdater();
                    } else {
                      provider.cancelLocUpdater();
                    }
                  },
                );
              },
            ),
            const Divider(),
            Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  appLocalizations.about,
                  style: Theme.of(context).textTheme.caption,
                )),
            ListTile(
              title: Text(appLocalizations.license),
              onTap: () {
                showLicensePage(context: context);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const AboutPage()),
                // );
              },
            )
          ],
        ));
  }
}

class LanguagePage extends StatelessWidget {
  final Locale? selected;
  const LanguagePage({Key? key, this.selected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;

    var languageChoices = AppLocalizations.supportedLocales
        .map((locale) => MapEntry(LocaleUtil.locale2Key(locale),
            LocaleUtil.locale2String(locale) ?? ''))
        .toList();
    languageChoices.insert(
        0, MapEntry('system', appLocalizations.systemLanguage));

    var selectedLocale = selected;
    var selectedKey = selectedLocale == null
        ? 'system'
        : LocaleUtil.locale2Key(selectedLocale);

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.language)),
      body: ListView(
        children: [
          for (var locale in languageChoices)
            ListTile(
              leading: selectedKey == locale.key
                  ? Icon(Icons.radio_button_checked,
                      color: Theme.of(context).primaryColor)
                  : Icon(Icons.radio_button_unchecked,
                      color: Theme.of(context).primaryColor),
              title: Text(locale.value),
              onTap: () => Navigator.pop(context, locale.key),
            )
        ],
      ),
    );
  }
}

abstract class LocaleUtil {
  /// All language names must be defined here.
  /// Name of default will follow current language settings;
  /// Other names are specified in their own languages.
  /// key format: languageCode#countryCode
  static const _languageNames = {"en#": "English", "zh#": "繁體中文"};

  static String locale2Key(Locale locale) {
    return locale.languageCode + "#" + (locale.countryCode ?? '');
  }

  static String? locale2String(Locale? locale) {
    if (locale == null) {
      return null;
    } else {
      return _languageNames[locale2Key(locale)];
    }
  }

  static Locale? key2Locale(String key) {
    var strs = key.split('#');
    if (strs.length != 2) {
      return null;
    } else {
      return Locale(strs[0], strs[1] == '' ? null : strs[1]);
    }
  }
}
