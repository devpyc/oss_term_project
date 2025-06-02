import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// import 'configuration.dart';
import 'notification.dart';

import 'calendarPage.dart';
import 'timerPage.dart';
import 'settingsPage.dart';
import 'alarmPage.dart';
import 'package:alarm/alarm.dart';
import 'configuration.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false); //다크모드

StreamController<String> streamController = StreamController.broadcast();

// @pragma('vm:entry-point')
// void notificationTapBackground(NotificationResponse response) {
//   // 백그라운드에서 알림 클릭 시 동작
// }

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> initializeNotifications() async {
//   const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

//   const InitializationSettings initializationSettings = InitializationSettings(
//     iOS: initializationSettingsIOS,
//   );

//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) {
//       // 알림 클릭 시 동작 정의
//     },
//     onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
//   );

//   // 권한 요청 (iOS) 알림, 뱃지, 사운드
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
//       ?.requestPermissions(alert: true, badge: true, sound: true);
// }


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  await StaticVariableSet.loadAllSettings();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);

  FlutterLocalNotification.onBackgroundNotificationResponse();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  var _index = 1;

  int timercho = 0;
  late Timer _timer;

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timercho == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          timercho--;
        });
      }
    });
  }

  final List<Widget> _pages = [
  List<Widget> _pages = [
    CalendarPage(),
    TimerPage(),
    SettingsPage()
  ];

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
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: const AlarmPage()
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: FlutterLocalNotification.showNotification,
      //   tooltip: '알람test',
      //   child: const Icon(Icons.add),
      // ),
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