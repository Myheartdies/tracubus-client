import 'package:flutter/material.dart';

class RouteDetail extends StatefulWidget {
  final String routeId;
  const RouteDetail({Key? key, required this.routeId}) : super(key: key);

  @override
  _RouteDetailState createState() => _RouteDetailState();
}

class _RouteDetailState extends State<RouteDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.routeId)),
        body: Container(
            //todo: implement actual route page with map and routes
            child: Text("Sample Text")));
  }
}
