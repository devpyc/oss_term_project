import 'package:flutter/material.dart';
import 'dart:async';
import 'configuration.dart';
import 'calendarPage.dart';
import 'timerPage.dart';
import 'settingsPage.dart';
import 'alarmPage.dart';
import 'package:flutter/services.dart'; //다크모드
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false); //다크모드

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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

  List<Widget> _pages = [
    CalendarPage(),
    TimerPage(),
    SettingsPage()
  ];

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
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
      body: _pages[_index],
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
      bottomNavigationBar: BottomNavigationBar(
        // showSelectedLabels: false,
        // showUnselectedLabels: false,
        currentIndex: _index,
        onTap: (value) {
          setState(() {
            _index = value;
            // print(_index);
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