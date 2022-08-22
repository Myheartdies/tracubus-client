import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import 'businfo_model.dart';
import 'location_model.dart';
import 'route_detail.dart';

class ETAPage extends StatefulWidget {
  const ETAPage({Key? key}) : super(key: key);

  @override
  _ETAPageState createState() => _ETAPageState();
}

class _ETAPageState extends State<ETAPage> {
  DateTime _utcNow = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();

    setState(() => _utcNow = DateTime.now().toUtc());
    Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() => _utcNow = DateTime.now().toUtc());
    });
  }

  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;
    var currentLocale = Localizations.localeOf(context);
    var localeKey = BusInfoModel.locale2Key(currentLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.arrivalTime),
      ),
      body: Consumer3<BusInfoModel, BusLocationModel, LocationModel>(
          builder: (context, infoModel, busLocModel, locModel, child) {
        var _busInfo = infoModel.busInfo;
        if (infoModel.fetchError) {
          return Center(child: Text(appLocalizations.fetchError));
        } else if (infoModel.dataError) {
          return Center(child: Text(appLocalizations.dataError));
        } else if (_busInfo == null) {
          return Center(
            child: Text(appLocalizations.fetching),
          );
        }

        Map<String, Stop> stops = _busInfo.stops.map((key, stop) {
          var c = _busInfo.points[stop];
          var loc = LatLng(c[0], c[1]);
          var name = _busInfo.strings[localeKey]?.stationName[key] ?? '';
          return MapEntry(key, Stop(key, name, loc));
        });

        // If a bus will pass the stop, and the stop is not the last stop
        // in the route, then add the route to it
        var buses = busLocModel.busLocations;
        if (buses != null && buses.isNotEmpty) {
          for (var bus in buses) {
            stops.forEach((key, stop) {
              var time = BusInfoModel.estimatedTime(stop.key, bus, _busInfo);
              if (time >= 0) {
                var routeId = bus.route;
                var routeName =
                    _busInfo.strings[localeKey]?.route[routeId]?.name ?? '';
                var route = Route(routeId, routeName, time);
                stop.routes.add(route);
              }
            });
          }
        }

        // For each route, predict the next bus:
        for (var route in _busInfo.routes.entries) {
          // For this route, predict next starting time
          var next = BusInfoModel.calculateTimeForNextBus(route.value, _utcNow);
          if (next < 0) continue;
          // After [next] seconds, a bus will start from its first stop.

          var routeName =
              _busInfo.strings[localeKey]?.route[route.key]?.name ?? '';
          // For each stop, add this route, except the last stop
          for (var i = 0; i < route.value.pieces.length - 1; i++) {
            late int time;
            if (i == 0) {
              time = 0;
            } else {
              var _time = route.value.avgTime['0-$i'];
              if (_time == null) continue;
              time = _time;
            }
            time = time + next;
            stops[route.value.pieces[i].stop]!
                .routes
                .add(Route(route.key, routeName, time));
          }
        }

        // Sort the routes by time
        stops.forEach((key, stop) {
          stop.routes.sort((s1, s2) => s1.time.compareTo(s2.time));
          // Filter out results whose time is longer than an hour
          stop.routes.removeWhere((route) => route.time > 3600);
        });

        var lat = locModel.latitude;
        var lng = locModel.longitude;
        bool sortEnabled = lat != null && lng != null;

        var stopList = stops.values.toList(growable: false);
        if (sortEnabled) {
          // Sort the stops by distance
          var distance = const Distance();
          var myLoc = LatLng(lat, lng);
          stopList.sort((s1, s2) => distance
              .as(LengthUnit.Meter, myLoc, s1.loc)
              .compareTo(distance.as(LengthUnit.Meter, myLoc, s2.loc)));
        } else {
          // Sort the stops by alphabet
          stopList.sort((a, b) => a.name.compareTo(b.name));
        }

        var textTheme = Theme.of(context).textTheme;
        return Column(children: [
          if (!sortEnabled)
            Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  appLocalizations.sortHint,
                  style: textTheme.caption,
                )),
          Expanded(
              child: ListView.builder(
            itemCount: stopList.length,
            itemBuilder: (context, index) {
              var stop = stopList[index];
              String? distance;
              if (sortEnabled) {
                var d = const Distance()
                    .as(LengthUnit.Meter, stop.loc, LatLng(lat, lng))
                    .ceil();
                distance = d.toString() +
                    ' ' +
                    appLocalizations.meter +
                    (d > 1 ? appLocalizations.plural : '');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                      color: Colors.blue.shade100,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(
                              stop.name,
                              style: textTheme.bodyText1,
                              textAlign: TextAlign.start,
                            ),
                            if (sortEnabled) Expanded(child: Container()),
                            if (sortEnabled)
                              Text(
                                distance ?? '',
                                style: textTheme.caption,
                              ),
                          ]),
                          Text(
                            _busInfo.routes.entries
                                .where((element) => element.value.pieces
                                    .any((element) => element.stop == stop.key))
                                .map((e) => e.key)
                                .join(' '),
                            style: textTheme.caption,
                          ),
                        ],
                      )),
                  if (stop.routes.isNotEmpty)
                    for (var route in stop.routes)
                      ListTile(
                          title: Text(route.id),
                          subtitle: Text(route.name),
                          trailing: Text(BusInfoModel.timeToString(
                              route.time, appLocalizations)),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteDetail(
                                  routeId: route.id,
                                  busInfo: _busInfo,
                                ),
                              ))),
                  // Add a placeholder when routes are empty
                  if (stop.routes.isEmpty)
                    Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          appLocalizations.noBusArriving,
                          style: textTheme.bodyText2,
                          textAlign: TextAlign.start,
                        ))
                ],
              );
            },
          ))
        ]);
      }),
    );
  }
}

class Stop {
  final String key;
  final String name;
  final LatLng loc;
  final List<Route> routes = [];

  Stop(this.key, this.name, this.loc);
}

class Route {
  final String id;
  final String name;
  final int time;

  Route(this.id, this.name, this.time);
}
