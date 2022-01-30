import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';

import 'businfo.dart';
import 'businfo_model.dart';

class RouteDetail extends StatefulWidget {
  final String routeId;
  const RouteDetail({Key? key, required this.routeId}) : super(key: key);

  @override
  _RouteDetailState createState() => _RouteDetailState();
}

class _RouteDetailState extends State<RouteDetail> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BusInfoModel, BusLocationModel>(
        builder: (context, infoModel, locationModel, child) {
      var _busInfo = infoModel.busInfo;
      var routeId = widget.routeId;
      var route = _busInfo?.routes[routeId];

      Widget? map, details, hint;

      // There are two cases here:
      // 1. No error: map and details are shown;
      // 2. Some error occured: only hint is shown.

      if (_busInfo == null || route == null || route.pieces.isEmpty) {
        hint = Expanded(
          child: Center(
            child: Text(
                'Route "$routeId" does not exist, or the route is invalid.'),
          ),
        );
      } else {
        // Real-time locations of buses
        var _busLocations = locationModel.busLocations
                ?.where((e) => e.route == routeId)
                .toList() ??
            const <BusLocation>[];

        // For drawing buses
        List<LatLng> stopsLatLng = [];
        // For highlighting routes
        List<List<LatLng>> routePolyLines = [];

        var allStops = _busInfo.stops;
        var allPts = _busInfo.points;
        var allSegs = _busInfo.segments;

        for (var e in route.pieces) {
          List<LatLng> polyLine = [];
          if (allStops.containsKey(e.stop)) {
            // TODO: Use offset(?) to align the icon
            stopsLatLng.add(LatLng(
              allPts[allStops[e.stop]!][0],
              allPts[allStops[e.stop]!][1],
            ));
            for (var s in e.segs) {
              for (var p in allSegs[s]) {
                polyLine.add(LatLng(allPts[p][0], allPts[p][1]));
              }
            }
          }
          routePolyLines.add(polyLine);
        }

        // Construct the map
        map = Expanded(
          child: FlutterMap(
            options: MapOptions(
              // TODO: change the range of diplay?
              bounds: LatLngBounds(
                  LatLng(22.42627619039879, 114.20044875763406),
                  LatLng(22.412296074471833, 114.21381802755778)),
              boundsOptions:
                  const FitBoundsOptions(padding: EdgeInsets.all(8.0)),
              maxZoom: 19,
              minZoom: 15,
            ),
            layers: [
              TileLayerOptions(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                maxNativeZoom: 19,
                maxZoom: 19,
                minZoom: 15,
              ),
              PolylineLayerOptions(
                polylines: [
                  for (var l in routePolyLines)
                    Polyline(
                      points: l,
                      strokeWidth: 2.0,
                      gradientColors: [
                        Colors.red,
                      ],
                    ),
                ],
              ),
              MarkerLayerOptions(
                markers: [
                  // Buses
                  for (var busLocation in _busLocations)
                    Marker(
                      width: 20.0,
                      height: 20.0,
                      point: LatLng(
                        busLocation.latitude,
                        busLocation.longitude,
                      ),
                      builder: (ctx) => const Icon(
                        CupertinoIcons.bus,
                        color: Colors.blue,
                      ),
                    ),
                  // Stops
                  for (var stop in stopsLatLng)
                    Marker(
                      width: 20.0,
                      height: 20.0,
                      point: stop,
                      builder: (ctx) => const Icon(
                        CupertinoIcons.location,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
        details = Expanded(
          child: Text(
            route.pieces.map((e) => e.stop).toList().toString(),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text(route?.name ?? '')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (map != null) map,
            if (details != null) details,
            if (hint != null) hint,
          ],
        ),
      );
    });
  }
}
