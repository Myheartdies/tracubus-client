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
    return Scaffold(
      appBar: AppBar(title: Text(widget.routeId)),
      body: Consumer2<BusInfoModel, BusLocationModel>(
        builder: (context, infoModel, locationModel, child) {
          var _busInfo = infoModel.busInfo;
          var stops = _busInfo?.routes[widget.routeId];
          var routeId = widget.routeId;

          Widget? map, details, hint;

          // There are two cases here:
          // 1. No error: map and details are shown;
          // 2. Some error occured: only hint is shown.
          if (_busInfo == null) {
            hint = const Expanded(
              child: Center(
                child: Text('Route information is not available.'),
              ),
            );
          } else if (stops?.isEmpty == null) {
            hint = Expanded(
              child: Center(
                child: Text(
                    'Route "$routeId" does not exist, or the route is invalid.'),
              ),
            );
          } else {
            var _busLocations = locationModel.busLocations;
            _busLocations =
                _busLocations?.where((e) => e.route == routeId).toList() ??
                    const <BusLocation>[];

            map = Expanded(
              child: FlutterMap(
                options: MapOptions(
                  bounds: LatLngBounds(
                      LatLng(22.42627619039879, 114.20044875763406),
                      LatLng(22.412296074471833, 114.21381802755778)),
                  boundsOptions:
                      const FitBoundsOptions(padding: EdgeInsets.all(8.0)),
                  maxZoom: 18,
                  minZoom: 14,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                    retinaMode: true,
                    maxNativeZoom: 18,
                    maxZoom: 19,
                    minZoom: 13,
                  ),
                  PolylineLayerOptions(
                    polylines: [
                      // TODO: Draw route
                      Polyline(
                        points: <LatLng>[
                          LatLng(22.42627619039879, 114.20044875763406),
                          LatLng(22.412296074471833, 114.21381802755778),
                        ],
                        strokeWidth: 2.0,
                        gradientColors: [
                          const Color(0xffE40203),
                        ],
                      ),
                    ],
                  ),
                  MarkerLayerOptions(
                    markers: [
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
                    ],
                  ),
                ],
              ),
            );
            details = Expanded(
              child: Text(
                _busLocations
                    .map((e) => jsonEncode(e.toJson()))
                    .toList()
                    .toString(),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (map != null) map,
              if (details != null) details,
              if (hint != null) hint,
            ],
          );
        },
      ),
    );
  }
}
