import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'about_page.dart';

class OthersPage extends StatelessWidget {
  const OthersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Others')),
      body: ListView(children: [
        ListTile(
          title: Text(AppLocalizations.of(context)!.helloWorld +
              AppLocalizations.of(context)!.localeName),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutPage()),
            );
          },
        )
      ]),
    );
  }
}
