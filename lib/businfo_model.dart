import 'package:flutter/foundation.dart';

/// This model extends ChangeNotifier and holds infomation fetched from server
class BusInfoModel extends ChangeNotifier {
  Map<String, int> busLocation = {'1A': 0, '2': 0};

  void updateLocation(Map<String, int> location) {
    busLocation = location;
    notifyListeners();
  }
}
