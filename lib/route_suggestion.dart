import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:awesome_select/awesome_select.dart';
import 'businfo.dart';

import 'route_detail.dart';
import 'businfo_model.dart';

class RouteSuggest extends StatefulWidget {
  const RouteSuggest({Key? key}) : super(key: key);

  @override
  _RouteSuggestState createState() => _RouteSuggestState();
}

class _RouteSuggestState extends State<RouteSuggest> {
  var _srcStopId = '', _destStopId = '';

  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;
    var currentLocale = Localizations.localeOf(context);
    var localeKey = BusInfoModel.locale2Key(currentLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.searchRoutes),
      ),
      body: Consumer<BusInfoModel>(builder: (context, infoModel, child) {
        var _busInfo = infoModel.busInfo;
        if (infoModel.errorOccured) {
          return Center(
            child: Text(appLocalizations.fetchError),
          );
        } else if (_busInfo == null) {
          return Center(
            child: Text(appLocalizations.fetching),
          );
        }

        // TODO: Use place here
        var stopKeys = _busInfo.stops.keys.toList(growable: false);
        var stopList = stopKeys.map((key) {
          return S2Choice(
              value: key,
              title: _busInfo.strings[localeKey]?.stationName[key] ?? '');
        }).toList();
        stopList.sort((s1, s2) => s1.title!.compareTo(s2.title!));

        var routeResults = <RouteResult>[];
        _busInfo.routes.forEach((routeId, route) {
          var srcIdx =
              route.pieces.indexWhere((stop) => stop.stop == _srcStopId);
          var destIdx =
              route.pieces.indexWhere((stop) => stop.stop == _destStopId);
          var time = route.avgTime['$srcIdx-$destIdx'];
          if (time != null) {
            routeResults.add(RouteResult(routeId, route, time));
          }
        });

        return Column(children: [
          Column(
            children: [
              SmartSelect<String>.single(
                title: appLocalizations.from,
                selectedValue: _srcStopId,
                choiceItems: stopList,
                onChange: (selected) =>
                    setState(() => _srcStopId = selected.value ?? ''),
                modalType: S2ModalType.fullPage,
                modalFilter: true,
                modalFilterAuto: true,
                modalFilterHint: "Search starting place",
                tileBuilder: (context, state) {
                  var selectedKey = state.selected?.choice?.value;
                  var selectedTitle =
                      _busInfo.strings[localeKey]?.stationName[selectedKey] ??
                          '';

                  return ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(appLocalizations.from)],
                    ),
                    title: Text(selectedTitle),
                    trailing: const Icon(Icons.navigate_next),
                    onTap: state.showModal,
                  );
                },
              ),
              const Divider(),
              SmartSelect<String>.single(
                title: appLocalizations.to,
                selectedValue: _destStopId,
                choiceItems: stopList,
                onChange: (selected) =>
                    setState(() => _destStopId = selected.value ?? ''),
                modalType: S2ModalType.fullPage,
                modalFilter: true,
                modalFilterAuto: true,
                modalFilterHint: "Search destination",
                tileBuilder: (context, state) {
                  var selectedKey = state.selected?.choice?.value;
                  var selectedTitle =
                      _busInfo.strings[localeKey]?.stationName[selectedKey] ??
                          '';

                  return ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(appLocalizations.to)],
                    ),
                    title: Text(selectedTitle),
                    trailing: const Icon(Icons.navigate_next),
                    onTap: state.showModal,
                  );
                },
              ),
            ],
          ),
          Divider(
            color: Theme.of(context).primaryColor,
            thickness: 2,
          ),
          Expanded(
            child: ListView.builder(
                itemCount: routeResults.length,
                itemBuilder: (context, index) {
                  RouteResult route = routeResults[index];
                  var routeName =
                      _busInfo.strings[localeKey]?.route[route.routeId]?.name ??
                          '';
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: ListTile(
                        title: Text(route.routeId),
                        subtitle: Text(routeName),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              appLocalizations.ett,
                              style: Theme.of(context).textTheme.caption,
                            ),
                            Text(route.duration +
                                ' ' +
                                appLocalizations.minute +
                                (route.plural ? appLocalizations.plural : ''))
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RouteDetail(
                                      routeId: route.routeId,
                                      busInfo: _busInfo,
                                      startStopId: _srcStopId,
                                      endStopId: _destStopId,
                                    )),
                          );
                        }),
                  );
                }),
          )
        ]);
      }),
    );
  }
}

class RouteResult {
  final String routeId;
  final BusRoute route;
  final int time;

  RouteResult(this.routeId, this.route, this.time);

  /// In minutes
  String get duration {
    if (time < 30) {
      return '0.5';
    } else {
      return ((time + 30) ~/ 60).toString();
    }
  }

  bool get plural {
    return (time + 30) ~/ 60 > 1;
  }
}
