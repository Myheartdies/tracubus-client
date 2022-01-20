import 'package:flutter/material.dart';
import 'route_detail.dart';

class RoutePage extends StatefulWidget {
  final List<Map>? routes;

  const RoutePage({Key? key, required this.routes}) : super(key: key);

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Routes'),
      ),
      body: _buildList(),
    );
  }

  Widget _buildList() {
    var routes = widget.routes;
    if (routes == null) {
      return const Center(child: Text('Fetching data...'));
    } else {
      return ListView.builder(
        itemCount: routes.length * 2,
        itemBuilder: (context, i) {
          if (i.isOdd) return const Divider();
          final index = i ~/ 2;
          var route = routes[index];
          return ListTile(
              title: Text(route['id']),
              subtitle: Text(route['name']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          RouteDetail(routeId: route['id'])),
                );
              }); /*Text(i.toString());*/
        },
      );
    }
  }
}
