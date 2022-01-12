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
  // TODO: replace this with actual bus data to be passed to each page
  int? now;
  var ListOfAllBus=[['1A','本部线'],['1B','本部线'],['2','新联线']];

  int _selectedIndex = 0;
  static const List<String> _pages = [//This is causing trouble for route page implementation 
    "Routes",                         //Yu's route page implmentation use a constructor which is unusable in this case
    "EAT",
    "Search",
    "Others",
  ];
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
    // Periodically get bus information from server
    // TODO: currently use time here for testing
    Timer.periodic(const Duration(seconds: 1), (timer) {
      int now = DateTime.now().second;
      setState(() {
        this.now = now;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO: change app bar based on bottom nav
      appBar: AppBar(
        title: const Text('Tracubus'),
      ),
      body: Center(
          child: IndexedStack(
        index: _selectedIndex,
        // TODO: Construct pages
        children: [
          RoutePage(BusList: ListOfAllBus),
          for (var t in _pages)
            Text("$t ${now == null ? 'time not available' : now.toString()}")
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
