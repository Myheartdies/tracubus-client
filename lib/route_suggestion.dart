import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:awesome_select/awesome_select.dart';
import 'package:latlong2/latlong.dart';
import 'businfo.dart';

import 'route_detail.dart';
import 'businfo_model.dart';

class RouteSuggest extends StatefulWidget {
  const RouteSuggest({Key? key}) : super(key: key);

  @override
  _RouteSuggestState createState() => _RouteSuggestState();
}

class _RouteSuggestState extends State<RouteSuggest> {
  String? _srcPlaceId, _destPlaceId;
  bool _fuzzyEnabled = false;

  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;
    var currentLocale = Localizations.localeOf(context);
    var localeKey = BusInfoModel.locale2Key(currentLocale);

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

        // Choices generated from places
        var placeList = _busInfo.places.keys.toList(growable: false).map((key) {
          return S2Choice(
              value: key, title: placeName(key, _busInfo, localeKey));
        }).toList();
        placeList.sort((s1, s2) => s1.title!.compareTo(s2.title!));

        List<RouteResult> searchResults = [];
        List<RouteResult> fuzzySearchResults = [];
        if (_srcPlaceId != null && _destPlaceId != null) {
          searchByPlace(_busInfo, searchResults, _srcPlaceId!, _destPlaceId!);
          // Exact results are sorted by routeId
          searchResults
              .sort((e1, e2) => BusInfoModel.compare(e1.routeId, e2.routeId));
          if (_fuzzyEnabled) {
            fuzzySearchResults
                .addAll(fuzzySearch(_busInfo, _srcPlaceId!, _destPlaceId!));
            // For fuzzy results, they should be sorted by distance first
            // and then by routeId.
            fuzzySearchResults.sort((r1, r2) {
              // First check whether they are the same station.
              // Some stations share the same name although they have
              // different ids, and they are considered as identical
              // when showing to users. So we compare them by name instead
              // of id.
              var r1SrcName =
                  _busInfo.strings[localeKey]?.stationName[r1.srcId];
              var r1DstName =
                  _busInfo.strings[localeKey]?.stationName[r1.dstId];
              var r2SrcName =
                  _busInfo.strings[localeKey]?.stationName[r2.srcId];
              var r2DstName =
                  _busInfo.strings[localeKey]?.stationName[r2.dstId];
              if (r1SrcName == r2SrcName && r1DstName == r2DstName) {
                return 0;
              } else {
                // Not same station, compare distances
                var d1Src = distance(_busInfo, _srcPlaceId!, r1.srcId);
                var d1Dst = distance(_busInfo, _destPlaceId!, r1.dstId);
                var distance1 = d1Src + d1Dst;

                var d2Src = distance(_busInfo, _srcPlaceId!, r2.srcId);
                var d2Dst = distance(_busInfo, _destPlaceId!, r2.dstId);
                var distance2 = d2Src + d2Dst;

                var dist = distance1.compareTo(distance2);
                if (dist != 0) return dist;
              }
              // For stations with the same distance offset, compare keys
              return BusInfoModel.compare(r1.routeId, r2.routeId);
            });
          }
        }

        return Column(children: [
          Column(
            children: [
              SmartSelect<String>.single(
                title: appLocalizations.from,
                selectedValue: _srcPlaceId ?? '',
                choiceItems: placeList,
                onChange: (selected) =>
                    setState(() => _srcPlaceId = selected.value),
                modalType: S2ModalType.fullPage,
                modalFilter: true,
                modalFilterAuto: true,
                modalFilterHint: "Search starting place",
                tileBuilder: (context, state) {
                  late String selectedTitle;
                  var selectedKey = state.selected?.choice?.value;
                  if (selectedKey == null) {
                    selectedTitle = '';
                  } else {
                    selectedTitle = placeName(selectedKey, _busInfo, localeKey);
                  }

                  return ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(appLocalizations.from)],
                    ),
                    title: Text(selectedTitle),
                    trailing: const Icon(Icons.navigate_next),
                    onTap: state.showModal,
                  );
                },
              ),
              const Divider(),
              SmartSelect<String>.single(
                title: appLocalizations.to,
                selectedValue: _destPlaceId ?? '',
                choiceItems: placeList,
                onChange: (selected) =>
                    setState(() => _destPlaceId = selected.value),
                modalType: S2ModalType.fullPage,
                modalFilter: true,
                modalFilterAuto: true,
                modalFilterHint: "Search destination",
                tileBuilder: (context, state) {
                  late String selectedTitle;
                  var selectedKey = state.selected?.choice?.value;
                  if (selectedKey == null) {
                    selectedTitle = '';
                  } else {
                    selectedTitle = placeName(selectedKey, _busInfo, localeKey);
                  }

                  return ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(appLocalizations.to)],
                    ),
                    title: Text(selectedTitle),
                    trailing: const Icon(Icons.navigate_next),
                    onTap: state.showModal,
                  );
                },
              ),
              const Divider(),
              Row(children: [
                Checkbox(
                  value: _fuzzyEnabled,
                  onChanged: (v) {
                    setState(() {
                      _fuzzyEnabled = v ?? false;
                    });
                  },
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _fuzzyEnabled = !_fuzzyEnabled;
                    });
                  },
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                      child: Text(appLocalizations.fuzzy)),
                ),
                GestureDetector(
                  onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(appLocalizations.fuzzy),
                          content: Text(appLocalizations.fuzzyDesp),
                        );
                      }),
                  child: Icon(Icons.info_outline, color: Colors.grey.shade600),
                ),
              ]),
            ],
          ),
          Divider(
            color: Theme.of(context).primaryColor,
            thickness: 2,
          ),
          Expanded(
            child: ListView.builder(
                // searchResults + Divider + fuzzySearchResults
                itemCount: _fuzzyEnabled
                    ? searchResults.length + 1 + fuzzySearchResults.length
                    : searchResults.length,
                itemBuilder: (context, idx) {
                  late int index;
                  late RouteResult route;
                  if (idx == searchResults.length) {
                    return const Divider();
                  } else if (idx > searchResults.length) {
                    index = idx - searchResults.length - 1;
                    route = fuzzySearchResults[index];
                  } else {
                    index = idx;
                    route = searchResults[index];
                  }
                  return ListTile(
                      title: Text(route.routeId),
                      isThreeLine: true,
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_busInfo.strings[localeKey]
                                  ?.stationName[route.srcId] ??
                              ''),
                          Text(_busInfo.strings[localeKey]
                                  ?.stationName[route.dstId] ??
                              '')
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            appLocalizations.ett,
                            style: Theme.of(context).textTheme.caption,
                          ),
                          Text(route.duration +
                              ' ' +
                              appLocalizations.minute +
                              (route.plural ? appLocalizations.plural : ''))
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RouteDetail(
                                    routeId: route.routeId,
                                    busInfo: _busInfo,
                                    startStopIdx: route.srcIdx,
                                    endStopIdx: route.dstIdx,
                                  )),
                        );
                      });
                }),
          )
        ]);
      }),
    );
  }

  static String placeName(String key, BusInfo busInfo, String localeKey) {
    var stations = busInfo.places[key] ?? [];
    if (stations.length > 1) {
      /// For places with more than one stops, the name is given in
      /// strings -> place section.
      return busInfo.strings[localeKey]?.place[key] ?? '';
    } else if (stations.length == 1) {
      /// For places with only one stop, the name is the stop name
      return busInfo.strings[localeKey]?.stationName[stations[0]] ?? '';
    } else {
      return '';
    }
  }

  /// Compare two route result.
  static bool better(RouteResult r1, RouteResult r2) {
    if (r1.routeId != r2.routeId) {
      return false;
    }
    return r1.srcIdx >= r2.srcIdx && r1.dstIdx <= r2.dstIdx;
  }

  /// Add result to list if it's better and remove worse results from list.
  static bool tryAddResult(RouteResult result, List<RouteResult> list) {
    bool add = false;
    List<RouteResult> toRemove = [];
    int i = 0;
    for (; i < list.length; i++) {
      var r = list[i];
      if (better(result, r)) {
        toRemove.add(r);
        add = true;
      } else if (better(r, result)) {
        break;
      }
    }
    if (i == list.length) {
      add = true;
    }
    if (add) {
      list.add(result);
    }
    for (var r in toRemove) {
      list.remove(r);
    }
    return add;
  }

  /// Find route with src & dest station ID, in a specific route.
  /// This function assumes that busInfo is valid.
  /// Results are directly added into `results`. It stays clean (free of dup).
  static void searchByStationInRoute(BusInfo busInfo, List<RouteResult> results,
      String srcStation, String destStation, String routeId) {
    var route = busInfo.routes[routeId]!;
    // List all occurences of the stations in that route
    List<int> srcIdx = [];
    for (var i = 0; i < route.pieces.length; i++) {
      var piece = route.pieces[i];
      if (piece.stop == srcStation) {
        srcIdx.add(i);
      }
    }
    List<int> destIdx = [];
    for (var i = 0; i < route.pieces.length; i++) {
      var piece = route.pieces[i];
      if (piece.stop == destStation) {
        destIdx.add(i);
      }
    }
    // Try all combinations of the src & dest idx
    for (var src in srcIdx) {
      for (var dst in destIdx) {
        var time = route.avgTime['$src-$dst'];
        if (time == null) {
          continue;
        } else {
          // This result is valid: src-dst
          tryAddResult(
              RouteResult(
                  routeId, route, src, dst, srcStation, destStation, time),
              results);
        }
      }
    }
  }

  /// Find route with src & dest station ID, in all routes.
  /// This function assumes that busInfo is valid.
  /// Results are directly added into `results`. It stays clean (free of dup).
  static void searchByStation(BusInfo busInfo, List<RouteResult> results,
      String srcStation, String destStation) {
    // For all routes:
    var routes = busInfo.routes.keys.toList();
    for (var routeId in routes) {
      searchByStationInRoute(
          busInfo, results, srcStation, destStation, routeId);
    }
  }

  /// Find route with src & dest place ID, in all routes.
  /// This function assumes that busInfo is valid.
  /// Results are directly added into `results`.
  /// The results free of dup.
  static void searchByPlace(BusInfo busInfo, List<RouteResult> results,
      String srcPlaceId, String destPlaceId) {
    var srcStations = busInfo.places[srcPlaceId] ?? [];
    var destStations = busInfo.places[destPlaceId] ?? [];

    for (var srcStation in srcStations) {
      for (var destStation in destStations) {
        searchByStation(busInfo, results, srcStation, destStation);
      }
    }
  }

  /// This function assumes that busInfo is valid
  static LatLng station2loc(String stationId, BusInfo busInfo) {
    var loc = busInfo.points[busInfo.stops[stationId]!];
    return LatLng(loc[0], loc[1]);
  }

  /// This function assumes that busInfo is valid
  static LatLng place2loc(String placeId, BusInfo busInfo) {
    double latS = 0, lngS = 0;
    var stations = busInfo.places[placeId] ?? [];
    if (stations.isEmpty) {
      throw Exception('Place must have at least one station.');
    }
    for (var station in stations) {
      var loc = busInfo.points[busInfo.stops[station]!];
      latS = latS + loc[0];
      lngS = lngS + loc[1];
    }
    return LatLng(latS / stations.length, lngS / stations.length);
  }

  /// This function assumes that busInfo is valid
  static double distance(BusInfo busInfo, String placeId, String stationId) {
    return const Distance().as(LengthUnit.Meter, place2loc(placeId, busInfo),
        station2loc(stationId, busInfo));
  }

  /// This function assumes that busInfo is valid
  static List<String> findNearbyPlaces(BusInfo busInfo, String placeId) {
    LatLng placeLoc = place2loc(placeId, busInfo);

    var allPlaces = List<String>.from(busInfo.places.keys);
    allPlaces.remove(placeId);
    allPlaces.sort((place1Id, place2Id) {
      var place1Loc = place2loc(place1Id, busInfo);
      var place2Loc = place2loc(place2Id, busInfo);
      var distance = const Distance();
      return distance
          .as(LengthUnit.Meter, place1Loc, placeLoc)
          .compareTo(distance.as(LengthUnit.Meter, place2Loc, placeLoc));
    });
    return allPlaces;
  }

  /// Find route with src & dest place ID, in all routes with fuzzy
  /// search. Stations near src & dest place will be used.
  /// This function assumes busInfo is valid.
  /// <p>
  /// Results are returned as a new List;
  static List<RouteResult> fuzzySearch(
      BusInfo busInfo, String srcPlaceId, String destPlaceId) {
    // Find nearby stations of the selected places
    var srcNearbyPlaces = findNearbyPlaces(busInfo, srcPlaceId).sublist(0, 2);
    var destNearbyPlaces = findNearbyPlaces(busInfo, destPlaceId).sublist(0, 2);

    List<RouteResult> results1 = [];
    for (var p in srcNearbyPlaces) {
      searchByPlace(busInfo, results1, p, destPlaceId);
    }
    for (var p in destNearbyPlaces) {
      searchByPlace(busInfo, results1, srcPlaceId, p);
    }
    // results2 is not deduped with results1
    // because users may intentionally view those extra results
    // for fuzzy search
    List<RouteResult> results2 = [];
    for (var p1 in srcNearbyPlaces) {
      for (var p2 in destNearbyPlaces) {
        searchByPlace(busInfo, results2, p1, p2);
      }
    }
    return [...results1, ...results2];
  }
}

class RouteResult {
  final String routeId;
  final BusRoute route;
  final int srcIdx, dstIdx;
  final String srcId, dstId;
  final int time;

  RouteResult(this.routeId, this.route, this.srcIdx, this.dstIdx, this.srcId,
      this.dstId, this.time);

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
