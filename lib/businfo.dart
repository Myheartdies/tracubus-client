import 'package:json_annotation/json_annotation.dart';

part 'businfo.g.dart';

@JsonSerializable()
class StopInRoute {
  StopInRoute(this.name, this.segs);

  @JsonKey(required: true)
  final String name;

  @JsonKey(required: true)
  final List<int> segs;

  factory StopInRoute.fromJson(Map<String, dynamic> json) =>
      _$StopInRouteFromJson(json);

  Map<String, dynamic> toJson() => _$StopInRouteToJson(this);
}

@JsonSerializable()
class BusInfo {
  BusInfo(this.points, this.segments, this.stops, this.routes);

  /// points[idx] == [lat, lng]
  @JsonKey(required: true)
  final List<List<double>> points;

  /// segments[idx] == [point1Idx, point2Idx, ...]
  @JsonKey(required: true)
  final List<List<int>> segments;

  /// stops['id'] == pointIdx
  @JsonKey(required: true)
  final Map<String, int> stops;

  /// e.g.
  /// routes['1A'][0].name == 'shho',
  /// routes['1A'][0].segs == [0, 1, 2, 3]
  @JsonKey(required: true)
  final Map<String, List<StopInRoute>> routes;

  factory BusInfo.fromJson(Map<String, dynamic> json) =>
      _$BusInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BusInfoToJson(this);
}

@JsonSerializable()
class BusLocation {
  BusLocation(
    this.latitude,
    this.longitude,
    this.route,
    this.speed,
    this.stop,
    this.timestamp,
  );

  @JsonKey(required: true)
  final double latitude;

  @JsonKey(required: true)
  final double longitude;

  @JsonKey(required: true)
  final String route;

  @JsonKey(required: true)
  final double speed;

  @JsonKey(required: true)
  final int stop;

  @JsonKey(required: true)
  final int timestamp;

  factory BusLocation.fromJson(Map<String, dynamic> json) =>
      _$BusLocationFromJson(json);

  Map<String, dynamic> toJson() => _$BusLocationToJson(this);
}
