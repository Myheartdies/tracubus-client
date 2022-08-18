import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

import 'route_page.dart';
import 'eta_page.dart';
import 'route_suggestion.dart';
import 'others_page.dart';
import 'businfo_model.dart';
import 'settings_model.dart';

const baseUrl = "http://20.24.87.7:4242";
const ssePath = "/api/info-sse";
const routesPath = "/api/routes.json";

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BusLocationModel()),
        ChangeNotifierProvider(create: (context) => BusInfoModel()),
        ChangeNotifierProvider(create: (context) => SettingsModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
        builder: (context, settingsModel, child) => MaterialApp(
              title: 'Tracubus',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh', ''),
                Locale('en', ''),
              ],
              locale: settingsModel.locale,
              home: const MyHomePage(),
            ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

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
    registerBusLocUpdater();

    Provider.of<SettingsModel>(context, listen: false).initLocale();
  }

  void registerBusLocUpdater() {
    var url = baseUrl + ssePath;

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
        print("Confirm lost: Reconnect SSE");

        SSEClient.unsubscribeFromSSE();
        SSEClient.subscribeToSSE(url: url, header: {}).listen(
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
    late String j;
    try {
      var response = await http.get(Uri.parse(baseUrl + routesPath));
      j = response.body;
    } catch (e) {
      // print('Error fetching routes info: $e');
      // Most likely a network error, retry 3 seconds later
      Provider.of<BusInfoModel>(context, listen: false).setFetchError(true);
      Timer(const Duration(seconds: 3), () {
        Provider.of<BusInfoModel>(context, listen: false).resetState();
        fetchRoutes();
      });
      return;
    }
    Provider.of<BusInfoModel>(context, listen: false).updateBusInfo(j);
  }

  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context)!;
    var _bottomNavItems = [
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.list_number_rtl),
        label: appLocalizations.busRoutes,
      ),
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.bus),
        label: appLocalizations.arrivalTime,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.location_on),
        label: appLocalizations.searchRoutes,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.more_horiz),
        label: appLocalizations.others,
      ),
    ];

    return Scaffold(
      body: Center(
          child: IndexedStack(
        index: _selectedIndex,
        children: const [
          RoutePage(),
          ETAPage(),
          RouteSuggest(),
          OthersPage(),
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
