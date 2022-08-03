import 'package:json_annotation/json_annotation.dart';

part 'businfo.g.dart';

@JsonSerializable()
class BusRoute {
  BusRoute(
    this.departure,
    this.pieces,
    this.avgTime,
    this.minLat,
    this.maxLat,
    this.minLng,
    this.maxLng,
  );

  @JsonKey(required: true)
  final List<int> departure;

  @JsonKey(required: true)
  final List<StopInRoute> pieces;

  /// In seconds.
  /// For time from i to j, use `avgTime['$i-$j']`.
  /// Guarenteed to be non-negative.
  @JsonKey(defaultValue: <String, int>{})
  final Map<String, int> avgTime;

  @JsonKey(defaultValue: 90)
  double minLat;

  @JsonKey(defaultValue: 0)
  double maxLat;

  @JsonKey(defaultValue: 180)
  double minLng;

  @JsonKey(defaultValue: 0)
  double maxLng;

  factory BusRoute.fromJson(Map<String, dynamic> json) =>
      _$BusRouteFromJson(json);

  Map<String, dynamic> toJson() => _$BusRouteToJson(this);
}

@JsonSerializable()
class StopInRoute {
  StopInRoute(this.stop, this.segs, this.time);

  @JsonKey(required: true)
  final String stop;

  @JsonKey(required: true)
  final List<int> segs;

  /// In seconds
  @JsonKey(required: true)
  final int time;

  factory StopInRoute.fromJson(Map<String, dynamic> json) =>
      _$StopInRouteFromJson(json);

  Map<String, dynamic> toJson() => _$StopInRouteToJson(this);
}

@JsonSerializable()
class BusInfo {
  BusInfo(this.points, this.segments, this.stops, this.routes, this.strings, this.places);

  /// points[idx] == [lat, lng]
  @JsonKey(required: true)
  final List<List<double>> points;

  /// segments[idx] == [point1Idx, point2Idx, ...]
  @JsonKey(required: true)
  final List<List<int>> segments;

  /// stops['id'] == pointIdx
  @JsonKey(required: true)
  final Map<String, int> stops;

  @JsonKey(required: true)
  final Map<String, BusRoute> routes;

  @JsonKey(required: true)
  final Map<String, LanguageString> strings;

  @JsonKey(required: true)
  final Map<String, List<String>> places;

  factory BusInfo.fromJson(Map<String, dynamic> json) =>
      _$BusInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BusInfoToJson(this);
}

@JsonSerializable()
class RouteString {
  RouteString(this.name, this.info);

  @JsonKey(required: true)
  final String name;

  @JsonKey(required: true)
  final String info;

  factory RouteString.fromJson(Map<String, dynamic> json) =>
      _$RouteStringFromJson(json);

  Map<String, dynamic> toJson() => _$RouteStringToJson(this);
}

@JsonSerializable()
class LanguageString {
  LanguageString(this.stationName, this.route, this.place);

  @JsonKey(required: true)
  final Map<String, String> stationName;

  @JsonKey(required: true)
  final Map<String, RouteString> route;

  @JsonKey(required: true)
  final Map<String, String> place;

  factory LanguageString.fromJson(Map<String, dynamic> json) =>
      _$LanguageStringFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageStringToJson(this);
}

@JsonSerializable()
class BusLocation {
  BusLocation(
    this.id,
    this.latitude,
    this.longitude,
    this.route,
    this.speed,
    this.stop,
    this.timestamp,
    this.remaining,
  );

  @JsonKey(required: true)
  final String id;

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

  /// In seconds
  @JsonKey(required: true)
  final int remaining;

  factory BusLocation.fromJson(Map<String, dynamic> json) =>
      _$BusLocationFromJson(json);

  Map<String, dynamic> toJson() => _$BusLocationToJson(this);
}
