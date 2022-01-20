import 'package:flutter/material.dart';

import 'route_page.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracubus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Data fetched at app launch
  List<Map>? routes;

  int _selectedIndex = 0;
  static const _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Routes',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bus_alert),
      label: 'EAT',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.location_on),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.more_horiz),
      label: 'Others',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize data here
    fetchRoutes().then((v) {
      setState(() {
        routes = v;
      });
    });
    // fetchSomeData().then();

    // TODO: Periodically get bus location from server
    // Timer.periodic(duration, (timer) { });
  }

  Future<List<Map>> fetchRoutes() async {
    // TODO:
    return Future.delayed(const Duration(seconds: 5), () {
      return [
        {'id': '1A', 'name': 'Main Campus'},
        {'id': '3', 'name': 'Shaw'}
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: IndexedStack(
        index: _selectedIndex,
        children: [
          RoutePage(routes: routes),
          Text('test'),
          Text('test'),
          Text('test'),
        ],
      )),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavItems,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        showUnselectedLabels: true,
        unselectedItemColor: Colors.blueGrey,
        onTap: _onItemTapped,
      ),
    );
  }
}
