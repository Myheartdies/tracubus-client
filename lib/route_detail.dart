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
  List<LatLng> pts = [];
  var toImportStr = '', exportStr = '[]';

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
                  maxZoom: 19,
                  minZoom: 15,
                  onTap: (tapPosition, latlng) {
                    setState(() {
                      pts.add(latlng);
                    });
                  },
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                    retinaMode: false,
                    maxNativeZoom: 19,
                    maxZoom: 19,
                    minZoom: 15,
                  ),
                  PolylineLayerOptions(
                    polylines: [
                      // TODO: Draw route
                      Polyline(
                        points: pts,
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
            details = SizedBox(
              width: 300,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        toImportStr = value;
                      });
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      List ps = jsonDecode(toImportStr);
                      var a = ps.map((e) {
                        return LatLng(e[0], e[1]);
                      }).toList();
                      setState(() {
                        pts = a;
                      });
                    },
                    child: const Text('Import'),
                  ),
                  TextButton(
                    onPressed: () {
                      var t = pts
                          .map((e) {
                            var _lat = e.latitude.toStringAsFixed(6);
                            var _lon = e.longitude.toStringAsFixed(6);
                            return '[$_lat, $_lon]';
                          })
                          .toList()
                          .toString();
                      setState(() {
                        exportStr = t;
                      });
                      print(exportStr);
                    },
                    child: const Text('Export'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pts.length,
                      itemBuilder: (context, i) {
                        return Container(
                          child: Column(
                            children: [
                              Text('$i'),
                              TextFormField(
                                initialValue: pts[i].latitude.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    pts[i].latitude =
                                        double.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                              TextFormField(
                                initialValue: pts[i].longitude.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    pts[i].longitude =
                                        double.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    pts.removeAt(i);
                                  });
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          margin: const EdgeInsets.all(3.0),
                          padding: const EdgeInsets.all(8.0),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return Row(
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
