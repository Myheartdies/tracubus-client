import 'package:flutter/material.dart';
import 'RouteDetail.dart';
class RoutePage extends StatefulWidget {
  final List BusList;

  const RoutePage({Key? key, required this.BusList}) : super(key: key);

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
      body: _BuildList(),
    );
  }

  Widget _BuildList() {
    return ListView.builder(
        itemCount: widget.BusList.length*2,
        itemBuilder: (context, i) {
          if (i.isOdd) return const Divider();
          final index=i~/2;
          return ListTile(
              title:Text(widget.BusList[index][0]),
              subtitle: Text(widget.BusList[index][1]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RouteDetail(BusNum: widget.BusList[index][0])),
              );
            }
          ); /*Text(i.toString());*/
        },
    );
  }
}
