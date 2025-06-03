import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:alarm/alarm.dart';

import 'configuration.dart';
import 'notification.dart';

import 'calendarPage.dart';
import 'timerPage.dart';
import 'settingsPage.dart';
// import 'alarmPage.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false); //다크모드

StreamController<String> streamController = StreamController.broadcast();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);

  await Alarm.init();
  await StaticVariableSet.loadAllSettings();

  FlutterLocalNotification.onBackgroundNotificationResponse();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pomodoro Timer',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MyHomePage(title: 'Pomodoro Timer'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<TimerPageState> _timerPageKey = GlobalKey<TimerPageState>();
  
  var _index = 1;

  void _handleReset() {
    _timerPageKey.currentState?.reset();
  }

  void onTimeChanged(int value) {
    setState(() {
      StaticVariableSet.timerTimeWork = value;
    });
  }

  @override
  void initState() {
    FlutterLocalNotification.init();
    Future.delayed(
      const Duration(seconds: 3),
      FlutterLocalNotification.requestNotificationPermission()
    );
    super.initState();
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 0, 200),
        title: Text(widget.title),
        titleTextStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.notifications),
        //     onPressed: () {
        //       _scaffoldKey.currentState?.openEndDrawer();
        //     },
        //   ),
        // ],
      ),
      // endDrawer: SizedBox(
      //   width: MediaQuery.of(context).size.width,
      //   child: const AlarmPage()
      // ),
      body: IndexedStack(
        index: _index,
        children: [
          CalendarPage(),
          TimerPage(key: _timerPageKey),
          SettingsPage(onTimeChanged: (value) {
            _handleReset();
          })
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        // showSelectedLabels: false,
        // showUnselectedLabels: false,
        currentIndex: _index,
        onTap: (value) {
          setState(() {
            _index = value;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar', activeIcon: Icon(Icons.calendar_month)),
          BottomNavigationBarItem(icon: Icon(Icons.query_builder_rounded), label: 'Timer', activeIcon: Icon(Icons.watch_later)),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings', activeIcon: Icon(Icons.settings_suggest))
        ],
      ),
    );
  }
}