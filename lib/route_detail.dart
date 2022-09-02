import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'businfo.dart';
import 'businfo_model.dart';
import 'tracubus_custom_icon_icons.dart';

class RouteDetail extends StatefulWidget {
  final String routeId;
  final BusInfo busInfo;
  final int? startStopIdx;
  final int? endStopIdx;

  const RouteDetail(
      {Key? key,
      required this.routeId,
      required this.busInfo,
      this.startStopIdx,
      this.endStopIdx})
      : super(key: key);

  @override
  _RouteDetailState createState() => _RouteDetailState();
}

class _RouteDetailState extends State<RouteDetail>
    with TickerProviderStateMixin {
  String? selectedBusId;
  BusRoute? _route;

  final MapController mapController = MapController();
  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    setState(() {
      _route = widget.busInfo.routes[widget.routeId];
    });

    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      var index = widget.startStopIdx;
      if (index != null && widget.endStopIdx != null) {
        itemScrollController.scrollTo(
            index: index, duration: const Duration(milliseconds: 500));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusLocationModel>(builder: (context, locationModel, child) {
      var appLocalizations = AppLocalizations.of(context)!;
      var currentLocale = Localizations.localeOf(context);
      var localeKey = BusInfoModel.locale2Key(currentLocale);

      var _busInfo = widget.busInfo;
      var routeId = widget.routeId;
      var route = _route;
      String? routeName;

      Widget? map, details, hint;

      // There are two cases here:
      // 1. No error: map and details are shown;
      // 2. Some error occured: only hint is shown.

      if (route == null || route.pieces.isEmpty) {
        hint = Expanded(
          child: Center(child: Text(appLocalizations.invalidRoute)),
        );
      } else {
        var strings = widget.busInfo.strings;
        routeName = strings[localeKey]?.route[routeId]?.name;

        // Real-time locations of buses
        var _busLocations = locationModel.busLocations
                ?.where((e) => e.route == routeId)
                .toList() ??
            const <BusLocation>[];

        var _selectedBusLocation = selectedBusId == null
            ? null
            : _busLocations
                .firstWhereOrNull((element) => element.id == selectedBusId);

        // For drawing buses
        List<LatLng> stopsLatLng = [];
        // For highlighting routes
        List<Polyline> routePolyLines = [];
        var activeColor = Colors.red;
        var inactiveColor = Colors.red.shade100;

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
              _selectedBusLocation == null
                  ? activeColor
                  : (_selectedBusLocation.stop <= i
                      ? activeColor
                      : inactiveColor),
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
                // OSM humanitarian layer, which is more concise than default layer
                /* TODO: It's suggested by osm that the url should be provided in a
                 * way which allows switching without app update.
                 * See https://operations.osmfoundation.org/policies/tiles/#requirements
                 */
                urlTemplate:
                    "https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png",
                subdomains: ['a', 'b'],
                // Getting package name in flutter is inconvenience, so we
                // hardcode the ua using app name here
                userAgentPackageName: 'tracubus',
                maxNativeZoom: 19,
                maxZoom: 19,
                minZoom: 14,
                tileProvider: CustomTileProvider(),
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
                          if (bus.stop < 0 || bus.stop >= route.pieces.length) {
                            // Which means this bus is out of operation
                            var snackBar = SnackBar(
                              content: Text(appLocalizations.outOfOperation),
                              duration: const Duration(seconds: 2),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                            return;
                          }
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
            nonRotatedChildren: [
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                    color: const Color.fromARGB(180, 255, 255, 255),
                    // Corresponds to tile source
                    child: Text(
                      'tile © OpenStreetMap France, data © OpenStreetMap',
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ),
                  onTap: () {
                    // TODO: show attribution page
                  },
                ),
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
              var stopName =
                  _busInfo.strings[localeKey]?.stationName[stop.stop] ?? '';
              String? subtitle;
              if (i == widget.startStopIdx) {
                subtitle = appLocalizations.from;
              } else if (i == widget.endStopIdx) {
                subtitle = appLocalizations.to;
              }

              var iconData = i == 0
                  ? TracubusCustomIcon.top
                  : (i == route.pieces.length - 1
                      ? TracubusCustomIcon.bottom
                      : TracubusCustomIcon.middle);
              var theme = Theme.of(context);
              Widget aBigWidget = Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stopName),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: theme.textTheme.caption?.fontSize,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _selectedBusLocation == null
                          ? ''
                          : BusInfoModel.timeToString(
                              BusInfoModel.estimatedTime(
                                  stop.stop, _selectedBusLocation, _busInfo),
                              appLocalizations),
                      style: TextStyle(
                        fontSize: theme.textTheme.caption?.fontSize,
                      ),
                    ),
                  ),
                ],
              );
              if (_selectedBusLocation != null) {
                if (_selectedBusLocation.stop + 1 == i) {
                  aBigWidget = DefaultTextStyle(
                    style: TextStyle(color: theme.primaryColor),
                    child: aBigWidget,
                  );
                } else if (_selectedBusLocation.stop + 1 > i) {
                  aBigWidget = DefaultTextStyle(
                    style: const TextStyle(color: Colors.grey),
                    child: aBigWidget,
                  );
                }
              }

              return SizedBox(
                height: 64,
                child: LayoutBuilder(
                  builder: (context, constraints) => InkWell(
                    onTap: () {
                      if (allStops.containsKey(stop.stop)) {
                        var p = allPts[allStops[stop.stop]!];
                        _animatedMapMove(LatLng(p[0], p[1]), 17);
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 0, 24, 0),
                          child: SizedBox(
                            width: constraints.maxHeight / 512 * 232,
                            child: Icon(iconData,
                                size: constraints.maxHeight,
                                color: Colors.grey),
                          ),
                        ),
                        Expanded(child: aBigWidget),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text(routeName ?? '')),
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

class CustomTileProvider extends TileProvider {
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) =>
      CachedNetworkImageProvider(getTileUrl(coords, options), headers: headers);
}
