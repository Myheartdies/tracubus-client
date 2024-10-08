import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'route_detail.dart';
import 'businfo_model.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({Key? key}) : super(key: key);

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.busRoutes),
      ),
      body: _buildList(appLocalizations),
    );
  }

  Widget _buildList(AppLocalizations appLocalizations) {
    return Consumer<BusInfoModel>(builder: (context, infoModel, child) {
      var currentLocale = Localizations.localeOf(context);
      var localeKey = BusInfoModel.locale2Key(currentLocale);

      var _busInfo = infoModel.busInfo;

      if (infoModel.fetchError) {
        return Center(child: Text(appLocalizations.fetchError));
      } else if (infoModel.dataError) {
        return Center(child: Text(appLocalizations.dataError));
      } else if (_busInfo == null) {
        return Center(child: Text(appLocalizations.fetching));
      } else {
        var _routes = _busInfo.routes.entries.toList();
        _routes.sort((e1, e2) => BusInfoModel.compare(e1.key, e2.key));
        var _strings = _busInfo.strings;

        return ListView.builder(
          itemCount: _routes.length * 2,
          itemBuilder: (context, i) {
            if (i.isOdd) return const Divider(height: 8,);
            final index = i ~/ 2;
            var route = _routes.elementAt(index);

            var routeName = _strings[localeKey]?.route[route.key]?.name ?? '';

            return ListTile(
              title: Text(route.key),
              subtitle: Text(routeName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RouteDetail(
                            routeId: route.key,
                            busInfo: _busInfo,
                          )),
                );
              },
            );
          },
        );
      }
    });
  }
}
