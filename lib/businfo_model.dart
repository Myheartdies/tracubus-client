import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tracubus/businfo.dart';

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
        busInfo = _busInfo;
        notifyListeners();
        return;
      }
    } on Exception catch (e) {
      // TODO: log the exception

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
      for (var stop in route) {
        if (!busInfo.stops.containsKey(stop.name)) return false;
        for (var n in stop.segs) {
          if (n >= busInfo.segments.length) return false;
        }
      }
    }

    return true;
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
