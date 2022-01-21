import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Consumer<BusLocationModel>(
              builder: (context, locationModel, child) => FlutterMap(
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
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(
                            locationModel.busLocation[widget.routeId]
                                    ?.toDouble() ??
                                0,
                            -0.09),
                        builder: (ctx) => Container(
                          child: FlutterLogo(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // TODO: construct details page
          Consumer<BusLocationModel>(
              builder: (context, locationModel, child) =>
                  Expanded(child: Text('test ${locationModel.busLocation}')))
        ]));
  }
}
