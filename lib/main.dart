import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

import 'route_page.dart';
import 'route_suggestion.dart';
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
      icon: Icon(CupertinoIcons.list_number_rtl),
      label: 'Routes',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.bus),
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

    // Fetch information about routes, stops, etc.
    fetchRoutes();

    // Fetch realtime location of buses
    // registerBusLocUpdater();
  }

  void registerBusLocUpdater() {
    const url = "http://13.251.160.105:4242/api/info-sse";

    // The time when the bus location was updated
    int updateTime = 0;

    // Data older than oodTh seconds ago will be treated as outdated
    const int oodTh = 10;

    /// onData callback for SSE stream
    void dataHandler(event) {
      int now = DateTime.now().millisecondsSinceEpoch;
      var data = event.data;
      if (event.event == "bus-info" && data != null) {
        Provider.of<BusLocationModel>(context, listen: false)
            .updateLocation(data);
        // print('Updated at $now');
        updateTime = now;
      }
    }

    /// onError callback for SSE stream.
    /// e.g. failing to initialize the connetion / connection closed while receiving data.
    /// The callback doesn't reconnect. It only logs the error.
    void errorHandler(err) {
      // int now = DateTime.now().millisecondsSinceEpoch;
      // print("Error at $now");
      print(err);
    }

    /// Check if the location is outdated;
    /// if yes, close SSE connection (if any) and fire a new one.
    void checkBusLoc(timer) {
      int now = DateTime.now().millisecondsSinceEpoch;
      // print("Check if lost connection at $now...");

      if (now - updateTime > oodTh * 1000) {
        // print("Confirm lost: Reconnect SSE");

        SSEClient.unsubscribeFromSSE();
        SSEClient.subscribeToSSE(url, "").listen(
          dataHandler,
          onError: errorHandler,
          cancelOnError: true,
        );
      }
    }

    var timer = Timer.periodic(const Duration(seconds: oodTh), checkBusLoc);
    // Call the callback for an extra time to execute it immediately
    checkBusLoc(timer);
  }

  Future<void> fetchRoutes() async {
    // TODO: Fetch real data from server
    return Future.delayed(const Duration(seconds: 0), () {
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
        children: const [
          RoutePage(),
          Text('test'),
          RouteSuggest(),
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
