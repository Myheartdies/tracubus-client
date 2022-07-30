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
  var _srcStopName = '', _destStopName = '';
  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;

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

        var stopKeys = _busInfo.stops.keys.toList(growable: false);
        stopKeys.sort();
        var stopList = stopKeys.map((stopName) {
          return S2Choice(value: stopName, title: stopName);
        }).toList();

        var routeResults = <RouteResult>[];
        _busInfo.routes.forEach((routeId, route) {
          var srcIdx =
              route.pieces.indexWhere((stop) => stop.stop == _srcStopName);
          var destIdx =
              route.pieces.indexWhere((stop) => stop.stop == _destStopName);
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
                selectedValue: _srcStopName,
                choiceItems: stopList,
                onChange: (selected) =>
                    setState(() => _srcStopName = selected.value ?? ''),
                modalType: S2ModalType.fullPage,
                modalFilter: true,
                modalFilterAuto: true,
                modalFilterHint: "Search starting place",
                tileBuilder: (context, state) => ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(appLocalizations.from)],
                  ),
                  title: Text(state.selected?.choice?.title ?? ''),
                  onTap: state.showModal,
                ),
              ),
              const Divider(),
              SmartSelect<String>.single(
                title: appLocalizations.to,
                selectedValue: _destStopName,
                choiceItems: stopList,
                onChange: (selected) =>
                    setState(() => _destStopName = selected.value ?? ''),
                modalType: S2ModalType.fullPage,
                modalFilter: true,
                modalFilterAuto: true,
                modalFilterHint: "Search destination",
                tileBuilder: (context, state) => ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(appLocalizations.to)],
                  ),
                  title: Text(state.selected?.choice?.title ?? ''),
                  onTap: state.showModal,
                ),
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
                        subtitle: Text(route.route.name),
                        trailing: Text(route.duration +
                            ' ' +
                            appLocalizations.minute +
                            (route.plural ? appLocalizations.plural : '')),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    RouteDetail(routeId: route.routeId)),
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
