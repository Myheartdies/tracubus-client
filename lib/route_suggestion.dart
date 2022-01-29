import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'route_detail.dart';
import 'businfo_model.dart';

class RouteSuggest extends StatefulWidget {
  const RouteSuggest({Key? key}) : super(key: key);

  @override
  _RouteSuggestState createState() => _RouteSuggestState();
}

class _RouteSuggestState extends State<RouteSuggest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Route Suggestions"),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                child:TextField(
              
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Starting place',
                ),
              ),),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                child:TextField(
              
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Destination',
                ),
              ),),
            ],
          ),
        ));
  }
}
