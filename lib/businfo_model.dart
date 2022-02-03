import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'businfo.dart';

/// This model extends ChangeNotifier and holds infomation fetched from server
/// Initially `busInfo == null` and `errorOccured == false`.
/// Calling `updateBusInfo()` will update the two fileds accordingly.
class BusInfoModel extends ChangeNotifier {
  BusInfo? busInfo;
  bool errorOccured = false;

  /// Results:
  /// 1. `busInfo == null` and `errorOccured == false`: still fetching data
  /// 2. `busInfo == null` and `errorOccured == true`: wrong data
  /// 3. `busInfo != null`: success
  void updateBusInfo(String infoJson) {
    try {
      var _busInfo = BusInfo.fromJson(jsonDecode(infoJson));

      if (_validateBusInfo(_busInfo)) {
        // Pre-calculation
        _busInfo.routes.forEach((key, route) {
          var stops = route.pieces;
          // Average time between stops
          for (var i = 0; i < stops.length - 1; i++) {
            for (var j = i + 1; j < stops.length; j++) {
              var t = stops[j - 1].time;
              if (j == i + 1) {
                route.avgTime['$i-$j'] = t;
              } else {
                var lt = route.avgTime['$i-${j - 1}'];
                if (lt != null) {
                  route.avgTime['$i-$j'] = lt + t;
                }
              }
            }
          }
          // Range of map
          // The range is limited within CUHK
          // Both lat and lng are positive
          for (var stop in route.pieces) {
            for (var seg in stop.segs) {
              for (var pt in _busInfo.segments[seg]) {
                var point = _busInfo.points[pt];
                route.minLat = min(point[0], route.minLat);
                route.maxLat = max(point[0], route.maxLat);
                route.minLng = min(point[1], route.minLng);
                route.maxLng = max(point[1], route.maxLng);
              }
            }
          }
        });
        busInfo = _busInfo;
        notifyListeners();
        return;
      }
    } catch (e) {
      // TODO: log the exception
      print(e);
    }
    errorOccured = true;
    notifyListeners();
  }

  bool _validateBusInfo(BusInfo busInfo) {
    for (var seg in busInfo.segments) {
      for (var p in seg) {
        if (p >= busInfo.points.length) return false;
      }
    }

    for (var stop in busInfo.stops.values) {
      if (stop >= busInfo.points.length) return false;
    }

    for (var route in busInfo.routes.values) {
      for (var stop in route.pieces) {
        if (!busInfo.stops.containsKey(stop.stop)) return false;
        for (var n in stop.segs) {
          if (n >= busInfo.segments.length) return false;
        }
      }
    }

    return true;
  }

  static String timeString(String stopId, BusLocation bus, BusInfo busInfo) {
    int time = estimatedTime(stopId, bus, busInfo);
    return timeToString(time);
  }

  /// returns the time left for the bus to reach this stop
  /// -2: error, -1: passed
  static int estimatedTime(String stopId, BusLocation bus, BusInfo busInfo) {
    BusRoute? route = busInfo.routes[bus.route];
    if (route == null) return -2;

    int stopIdx = route.pieces.indexWhere((element) => element.stop == stopId);
    if (stopIdx == -1) return -2;

    int currentStop = bus.stop;
    if (stopIdx <= currentStop) return -1;

    if (stopIdx - currentStop == 1) {
      return bus.remaining;
    } else {
      int? avg = route.avgTime['${currentStop + 1}-$stopIdx'];
      if (avg == null) {
        return -1;
      } else {
        return bus.remaining + avg;
      }
    }
  }

  static String timeToString(int time) {
    if (time < 0) {
      return '-';
    } else if (time < 5) {
      return 'Arrived';
    } else if (time < 60) {
      return 'Arriving soon';
    } else {
      return '${time ~/ 60} min';
    }
  }
}

class BusLocationModel extends ChangeNotifier {
  List<BusLocation>? busLocations;

  void updateLocation(String json) {
    try {
      List<dynamic> _l = jsonDecode(json);
      busLocations = List<BusLocation>.from(
          _l.map((busLocation) => BusLocation.fromJson(busLocation)));
      notifyListeners();
    } catch (e) {
      // TODO: log the exception
    }
  }
}
