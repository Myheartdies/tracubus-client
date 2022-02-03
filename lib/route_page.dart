import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'route_detail.dart';
import 'businfo_model.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({Key? key}) : super(key: key);

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
    return Consumer<BusInfoModel>(builder: (context, infoModel, child) {
      var _routes = infoModel.busInfo?.routes;
      if (infoModel.errorOccured) {
        return const Center(
          child: Text('Error: Server returns invalid data.'),
        );
      } else if (_routes == null) {
        return const Center(
          child: Text('Fetching data...'),
        );
      } else {
        return ListView.builder(
          itemCount: _routes.entries.length * 2,
          itemBuilder: (context, i) {
            if (i.isOdd) return const Divider();
            final index = i ~/ 2;
            var route = _routes.entries.elementAt(index);
            return ListTile(
              title: Text(route.key),
              subtitle: Text(route.value.name),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RouteDetail(
                            routeId: route.key,
                          )),
                );
              },
            );
          },
        );
      }
    });
  }
}
