import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'test000.dart';
import 'test001.dart';
import 'test002.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Pomodoro Timer'),
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

  int timercho = 10;
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
    test000(),
    test001(),
    test002()
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
        // child: const alarmPage()
      ),
      body: _pages[_index],
      // body: Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     crossAxisAlignment: CrossAxisAlignment.center,
      //     children: <Widget>[
      //       Text('$timercho'),
      //       ElevatedButton(
      //         onPressed: () {
      //           if (!_timer.isActive) {
      //             timercho = 10;
      //             startTimer();
      //           }
      //         },
      //         child: Text(_timer.isActive ? '타이머 실행 중' : '타이머 시작')
      //       )
      //     ],
      //   ),
      // ),
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
