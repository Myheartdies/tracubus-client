import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Routes"),
      ),
      body: Consumer<BusInfoModel>(builder: (context, infoModel, child) {
        var _busInfo = infoModel.busInfo;
        if (infoModel.errorOccured) {
          return const Center(
            child: Text('Error: Server returns invalid data.'),
          );
        } else if (_busInfo == null) {
          return const Center(
            child: Text('Fetching data...'),
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
                title: 'From',
                selectedValue: _srcStopName,
                choiceItems: stopList,
                onChange: (selected) =>
                    setState(() => _srcStopName = selected.value ?? ''),
                modalType: S2ModalType.popupDialog,
                tileBuilder: (context, state) => ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [Text('From')],
                  ),
                  title: Text(state.selected?.choice?.title ?? ''),
                  onTap: state.showModal,
                ),
              ),
              const Divider(),
              SmartSelect<String>.single(
                title: 'To',
                selectedValue: _destStopName,
                choiceItems: stopList,
                onChange: (selected) =>
                    setState(() => _destStopName = selected.value ?? ''),
                modalType: S2ModalType.popupDialog,
                tileBuilder: (context, state) => ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [Text('To')],
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
                        trailing: Text(route.timeString),
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

  String get timeString {
    if (time < 30) {
      return '0.5 min';
    } else {
      return '${(time + 30) ~/ 60} min';
    }
  }
}
