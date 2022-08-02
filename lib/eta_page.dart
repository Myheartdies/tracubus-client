import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

import 'businfo_model.dart';
import 'businfo.dart';
import 'route_detail.dart';

import 'package:location/location.dart';

class ETAPage extends StatefulWidget {
  const ETAPage({Key? key}) : super(key: key);

  @override
  _ETAPageState createState() => _ETAPageState();
}

class _ETAPageState extends State<ETAPage> {
  bool _sortEnabled = false;
  double _lat = 0, _lng = 0;
  int _now = 0;

  @override
  void initState() {
    super.initState();

    setState(() => _now = DateTime.now().minute);
    Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() => _now = DateTime.now().minute);
    });
  }

  Future<LocationData?> _checkLocation(BuildContext context) async {
    Location location = Location();

    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        // TODO: show error?
        return null;
      }
    }
    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      await _requestHint(context);
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        await _requestFailedHint(context);
        return null;
      }
    }

    return await location.getLocation();
  }

  Future<void> _requestHint(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocalizations.permissionRequest),
          content: Text(appLocalizations.locationRequestDesp),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(appLocalizations.ok),
            )
          ],
        );
      },
    );
  }

  Future<void> _requestFailedHint(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocalizations.error),
          content: Text(appLocalizations.locationPermissionErr),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(appLocalizations.ok),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;
    var currentLocale = Localizations.localeOf(context);
    var localeKey = BusInfoModel.locale2Key(currentLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.arrivalTime),
        actions: [
          IconButton(
            onPressed: () {
              if (!_sortEnabled) {
                _checkLocation(context).then((data) {
                  if (data != null &&
                      data.latitude != null &&
                      data.longitude != null) {
                    setState(() {
                      _lat = data.latitude!;
                      _lng = data.longitude!;
                      _sortEnabled = true;
                    });
                  }
                });
              } else {
                setState(() => _sortEnabled = false);
              }
            },
            icon: Icon(
              _sortEnabled ? Icons.location_searching : Icons.location_disabled,
            ),
          )
        ],
      ),
      body: Consumer2<BusInfoModel, BusLocationModel>(
          builder: (context, infoModel, locationModel, child) {
        var _busInfo = infoModel.busInfo;
        if (infoModel.errorOccured) {
          return Center(child: Text(appLocalizations.fetchError));
        } else if (_busInfo == null) {
          return Center(
            child: Text(appLocalizations.fetching),
          );
        }

        Map<String, Stop> stops = _busInfo.stops.map((key, stop) {
          var c = _busInfo.points[stop];
          var loc = LatLng(c[0], c[1]);
          return MapEntry(key, Stop(key, loc));
        });

        // If a bus will pass the stop, add the route to it
        var buses = locationModel.busLocations;
        if (buses != null && buses.isNotEmpty) {
          for (var bus in buses) {
            stops.forEach((key, stop) {
              var time = BusInfoModel.estimatedTime(stop.name, bus, _busInfo);
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
        // For the first stops of each route, add the route to it
        for (var route in _busInfo.routes.entries) {
          var firstStop = route.value.pieces[0].stop;
          if (stops.containsKey(firstStop)) {
            int time = calculateTimeForFirstStop(route.value, _now);
            if (time >= 0) {
              var routeName =
                  _busInfo.strings[localeKey]?.route[route.key]?.name ?? '';
              stops[firstStop]!.routes.add(Route(route.key, routeName, time));
            }
          }
        }
        // Sort the routes by time
        stops.forEach((key, stop) {
          stop.routes.sort((s1, s2) => s1.time.compareTo(s2.time));
        });

        var stopList = stops.values.toList(growable: false);
        if (_sortEnabled) {
          // Sort the stops by distance
          var distance = const Distance();
          var myLoc = LatLng(_lat, _lng);
          stopList.sort((s1, s2) => distance
              .as(LengthUnit.Meter, myLoc, s1.loc)
              .compareTo(distance.as(LengthUnit.Meter, myLoc, s2.loc)));
        } else {
          // Sort the stops by alphabet
          stopList.sort((a, b) => a.name.compareTo(b.name));
        }

        var textTheme = Theme.of(context).textTheme;
        return Column(children: [
          if (!_sortEnabled)
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
              if (_sortEnabled) {
                var d = const Distance()
                    .as(LengthUnit.Meter, stop.loc, LatLng(_lat, _lng))
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
                      child: Row(children: [
                        Text(
                          stop.name,
                          style: textTheme.subtitle2,
                          textAlign: TextAlign.start,
                        ),
                        if (_sortEnabled) Expanded(child: Container()),
                        if (_sortEnabled)
                          Text(
                            distance ?? '',
                            style: textTheme.caption,
                          ),
                      ])),
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
                              builder: (context) =>
                                  RouteDetail(routeId: route.id)),
                        ),
                      ),
                  // Add a placeholder when routes are empty
                  if (stop.routes.isEmpty)
                    Container(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          appLocalizations.noBusArriving,
                          style: textTheme.caption,
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

  // TODO: Consider running time range?
  int calculateTimeForFirstStop(BusRoute route, int nowMinute) {
    int? time;
    for (var de in route.departure) {
      if (de < nowMinute) de = de + 60;
      time ??= de - nowMinute;
      time = min(time, de - nowMinute);
    }
    return time == null ? -2 : time * 60;
  }
}

class Stop {
  final String name;
  final LatLng loc;
  final List<Route> routes = [];

  Stop(this.name, this.loc);
}

class Route {
  final String id;
  final String name;
  final int time;

  Route(this.id, this.name, this.time);
}
