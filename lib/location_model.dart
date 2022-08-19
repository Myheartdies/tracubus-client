import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

/// To use location service, first call [checkLocationPermission],
/// and check its return value or [enabled].
class LocationModel extends ChangeNotifier {
  final Location _location;
  StreamSubscription<LocationData>? _subscription;
  bool enabled = false;
  double? latitude;
  double? longitude;

  /// Check and try to obtain location permission.
  ///
  /// This will update locationModel.[enabled] and return its value.
  Future<bool> checkLocationPermission() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        enabled = false;
        return enabled;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        enabled = false;
        return enabled;
      }
    }
    enabled = true;
    return enabled;
  }

  /// Register location listener.
  ///
  /// Will do nothing if location is not available or location is
  /// already listening.
  ///
  /// Returns false if location is not available; true otherwise.
  bool registerLocUpdater() {
    if (!enabled) {
      return false;
    }
    if (_subscription != null) {
      return true;
    }
    _subscription =
        _location.onLocationChanged.listen((LocationData currentLocation) {
      // Use current location
      latitude = currentLocation.latitude;
      longitude = currentLocation.longitude;
      notifyListeners();
    });
    return true;
  }

  /// Cancel location updater and clear location data.
  void cancelLocUpdater() {
    var s = _subscription;
    _subscription = null;
    s?.cancel().then((_) {
      latitude = null;
      longitude = null;
      notifyListeners();
    });
  }

  LocationModel() : _location = Location();
}