import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'businfo.dart';

/// This model extends ChangeNotifier and holds infomation fetched from server
/// Initially `busInfo == null`, `fetchError == false` and `dataError == false`.
/// Calling `updateBusInfo()` will update these fileds accordingly.
class BusInfoModel extends ChangeNotifier {
  BusInfo? busInfo;
  bool fetchError = false;
  bool dataError = false;

  void resetState() {
    busInfo = null;
    fetchError = false;
    dataError = false;
    notifyListeners();
  }

  void setFetchError(bool flag) {
    fetchError = flag;
    notifyListeners();
  }

  /// Results:
  /// 1. `busInfo == null` and `dataError == false`: still fetching data
  /// 2. `busInfo == null` and `dataError == true`: wrong data
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
    dataError = true;
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
      if (route.operation.period.length != 2) return false;
      for (var n in route.operation.period) {
        if (!_validateHMString(n)) return false;
      }
      if (route.operation.departure.isEmpty) return false;
      for (var n in route.operation.departure) {
        if (int.tryParse(n) == null) return false;
      }

      for (var stop in route.pieces) {
        if (!busInfo.stops.containsKey(stop.stop)) return false;
        for (var n in stop.segs) {
          if (n >= busInfo.segments.length) return false;
        }
      }
    }

    for (var locale in AppLocalizations.supportedLocales) {
      if (!busInfo.strings.keys.contains(locale2Key(locale))) return false;
    }

    return true;
  }

  static bool _validateHMString(String str) {
    var arr = str.split(':');
    if (arr.length != 2) return false;
    for (var num in arr) {
      var n = int.tryParse(num);
      if (n == null) return false;
    }
    return true;
  }

  static String locale2Key(Locale locale) {
    return locale.languageCode +
        (locale.countryCode == null || locale.countryCode == ''
            ? ''
            : '-' + locale.countryCode!);
  }

  /// returns the time left for the bus to reach this stop
  /// -1: passed, -2: error, -3: last stop
  static int estimatedTime(String stopId, BusLocation bus, BusInfo busInfo) {
    BusRoute? route = busInfo.routes[bus.route];
    if (route == null) return -2;

    int stopIdx = route.pieces.indexWhere((element) => element.stop == stopId);
    if (stopIdx == -1) return -2;
    if (stopIdx == route.pieces.length - 1) return -3;

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

  /// Calculate how long until the next bus starts.
  ///
  /// Returns time in seconds.
  /// If there is no more buses today, this will return a negative value.
  static int calculateTimeForNextBus(BusRoute route, DateTime datetime) {
    // Convert datetime to Hong Kong time in two steps:
    // 1. Convert local time to utc
    if (!datetime.isUtc) datetime = datetime.toUtc();
    // 2. Convert utc to "Hong Kong time" by directly add 8 hours
    // (This datetime is likely in broken state.)
    var _datetime = datetime.add(const Duration(hours: 8));

    // Check whether this route is in operation today
    if (_isHoliday(datetime) != route.operation.holiday) return -1;

    var timeStr = _datetime.hour.toString().padLeft(2, '0') +
        ':' +
        _datetime.minute.toString().padLeft(2, '0');

    if (timeStr.compareTo(route.operation.period[1]) > 0) {
      // No more buses today
      return -1;
    } else if (timeStr.compareTo(route.operation.period[0]) < 0) {
      // First not started yet
      var firstBusTime = route.operation.period[0].split(':');
      var firstHour = int.tryParse(firstBusTime[0]);
      var firstMinute = int.tryParse(firstBusTime[1]);
      if (firstHour == null || firstMinute == null) return -1;
      return ((firstHour - _datetime.hour) * 60 +
              firstMinute -
              _datetime.minute) *
          60;
    } else {
      int? time;
      for (var de in route.operation.departure) {
        var minute = int.tryParse(de);
        if (minute == null) return -1;
        if (minute < _datetime.minute) minute = minute + 60;
        time ??= minute - _datetime.minute;
        time = min(time, minute - _datetime.minute);
      }
      return time == null ? -1 : time * 60;
    }
  }

  /// Check whether the bus is in operation. Only consider starting time.
  static bool inOperationPeriod(String routeId, DateTime datetime, BusInfo businfo) {
    // Convert datetime to Hong Kong time in two steps:
    // 1. Convert local time to utc
    if (!datetime.isUtc) datetime = datetime.toUtc();
    // 2. Convert utc to "Hong Kong time" by directly add 8 hours
    // (This datetime is likely in broken state.)
    var _datetime = datetime.add(const Duration(hours: 8));

    var route = businfo.routes[routeId];
    if (route == null) return false;

    if (route.operation.holiday != _isHoliday(datetime)) return false;

    // Then check period
    var timeStr = _datetime.hour.toString().padLeft(2, '0') +
        ':' +
        _datetime.minute.toString().padLeft(2, '0');
    if (timeStr.compareTo(route.operation.period[0]) < 0 ||
        timeStr.compareTo(route.operation.period[1]) > 0) {
      return false;
    }

    return true;
  }

  /// hkDateTime should be utc DateTime
  static bool _isHoliday(DateTime utcDateTime) {
    // TODO: Currently only check Sunday
    return utcDateTime.add(const Duration(hours: 8)).weekday == 7;
  }

  static String timeToString(int time, AppLocalizations appLocalizations) {
    if (time < 0) {
      return '-';
    } else if (time < 5) {
      return appLocalizations.arrived;
    } else if (time < 60) {
      return appLocalizations.arrivingSoon;
    } else {
      var t = time ~/ 60;
      return t.toString() +
          ' ' +
          appLocalizations.minute +
          (t > 1 ? appLocalizations.plural : '');
    }
  }

  static int compare(String key1, String key2) {
    const routes = [
      '1A',
      '1B',
      '2',
      '3',
      '4',
      '8',
      '5',
      '6A',
      '6B',
      '7',
      'N',
      'H'
    ];
    var idx1 = routes.indexOf(key1);
    idx1 = idx1 == -1 ? 999 : idx1;
    var idx2 = routes.indexOf(key2);
    idx2 = idx2 == -1 ? 999 : idx2;
    return idx1.compareTo(idx2);
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
