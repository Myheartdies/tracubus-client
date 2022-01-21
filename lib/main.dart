import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'route_page.dart';
import 'businfo_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BusLocationModel()),
        ChangeNotifierProvider(create: (context) => BusInfoModel()),
      ],
      child: const MyApp(),
    ),
  );
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
    fetchRoutes();
    // fetchSomeData().then();

    // TODO: Periodically get bus location from server
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        int now = DateTime.now().second;
        Provider.of<BusLocationModel>(context, listen: false).updateLocation({
          '1A': now,
          '2': now,
        });
      });
    });
  }

  Future<void> fetchRoutes() async {
    // TODO: Fetch real data from server
    return Future.delayed(const Duration(seconds: 2), () {
      Provider.of<BusInfoModel>(context, listen: false).updateBusInfo('''
      {
  "points": [
    [1.12, 114.514], [3.345, 1.1], [19.19, 8.1]
  ],
  "segments": [
    [0, 1, 2]
  ],
  "stops": {
    "shho": 2,
    "uc": 0
  },
  "routes": {
    "1a": [
      {
        "name": "shho",
        "segs": [0]
      }
    ]
  }
}
      ''');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: IndexedStack(
        index: _selectedIndex,
        children: [
          RoutePage(),
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
