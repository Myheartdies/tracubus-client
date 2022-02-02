import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/cupertino.dart';

import 'businfo.dart';
import 'businfo_model.dart';

class RouteDetail extends StatefulWidget {
  final String routeId;
  const RouteDetail({Key? key, required this.routeId}) : super(key: key);

  @override
  _RouteDetailState createState() => _RouteDetailState();
}

class _RouteDetailState extends State<RouteDetail>
    with TickerProviderStateMixin {
  String? selectedBusId;
  BusLocation? selectedBusLocation;
  final MapController mapController = MapController();
  final ItemScrollController itemScrollController = ItemScrollController();

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

        selectedBusLocation = selectedBusId == null
            ? null
            : _busLocations
                .firstWhereOrNull((element) => element.id == selectedBusId);
        var _selectedBus = selectedBusLocation;

        // For drawing buses
        List<LatLng> stopsLatLng = [];
        // For highlighting routes
        List<Polyline> routePolyLines = [];
        var activeColor = Colors.red;
        var inactiveColor = Colors.red[100] ?? Colors.grey;

        var allStops = _busInfo.stops;
        var allPts = _busInfo.points;
        var allSegs = _busInfo.segments;

        route.pieces.forEachIndexed((i, e) {
          List<LatLng> polyLinePts = [];
          if (allStops.containsKey(e.stop)) {
            stopsLatLng.add(LatLng(
              allPts[allStops[e.stop]!][0],
              allPts[allStops[e.stop]!][1],
            ));
            for (var s in e.segs) {
              for (var p in allSegs[s]) {
                polyLinePts.add(LatLng(allPts[p][0], allPts[p][1]));
              }
            }
          }
          var line = Polyline(
            points: polyLinePts,
            strokeWidth: 2.0,
            gradientColors: [
              // When a bus is selected, the passed routes will
              // be shown in a lighter color
              _selectedBus == null
                  ? activeColor
                  : (_selectedBus.stop <= i ? activeColor : inactiveColor),
            ],
          );
          routePolyLines.add(line);
        });

        // Construct the map
        map = Expanded(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              bounds: LatLngBounds(
                LatLng(route.maxLat, route.minLng),
                LatLng(route.minLat, route.maxLng),
              ),
              boundsOptions:
                  const FitBoundsOptions(padding: EdgeInsets.all(30.0)),
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              maxZoom: 19,
              minZoom: 14,
              onTap: (tapPosition, point) {
                setState(() => selectedBusId = null);
              },
            ),
            layers: [
              TileLayerOptions(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                maxNativeZoom: 19,
                maxZoom: 19,
                minZoom: 14,
                tileProvider: const NonCachingNetworkTileProvider(),
              ),
              PolylineLayerOptions(
                polylines: routePolyLines,
              ),
              MarkerLayerOptions(
                markers: [
                  // Buses
                  for (var bus in _busLocations)
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: LatLng(bus.latitude, bus.longitude),
                      anchorPos: AnchorPos.exactly(Anchor(22, 15)),
                      builder: (ctx) => GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBusId = bus.id;
                          });
                          _animatedMapMove(
                            LatLng(bus.latitude, bus.longitude),
                            mapController.zoom,
                          );
                          itemScrollController.scrollTo(
                            index: bus.stop,
                            duration: const Duration(milliseconds: 10),
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.bus,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  // Stops
                  for (var stop in stopsLatLng)
                    Marker(
                      width: 20.0,
                      height: 20.0,
                      point: stop,
                      anchorPos: AnchorPos.exactly(Anchor(10, -3)),
                      builder: (ctx) => const Icon(
                        CupertinoIcons.location_solid,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
        details = Expanded(
          child: ScrollablePositionedList.builder(
              itemCount: route.pieces.length,
              itemScrollController: itemScrollController,
              itemBuilder: (context, i) {
                var stop = route.pieces[i];
                return ListTile(
                  selected:
                      _selectedBus == null ? false : _selectedBus.stop + 1 == i,
                  enabled:
                      _selectedBus == null ? true : _selectedBus.stop + 1 <= i,
                  // TODO: Change the icon
                  leading: const Icon(Icons.circle_outlined),
                  title: Text(stop.stop),
                  trailing: Text(
                    _selectedBus == null
                        ? ''
                        : BusInfoModel.timeString(
                            stop.stop, _selectedBus, _busInfo),
                  ),
                  onTap: () {
                    if (allStops.containsKey(stop.stop)) {
                      var p = allPts[allStops[stop.stop]!];
                      _animatedMapMove(LatLng(p[0], p[1]), 17);
                    }
                  },
                );
              }),
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

  // Taken from the library example
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final _latTween = Tween<double>(
        begin: mapController.center.latitude, end: destLocation.latitude);
    final _lngTween = Tween<double>(
        begin: mapController.center.longitude, end: destLocation.longitude);
    final _zoomTween = Tween<double>(begin: mapController.zoom, end: destZoom);

    var controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          _zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
}
