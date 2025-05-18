import 'package:flutter/material.dart';
import 'calendarPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        leading: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarPage()), // CalendarPage
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // configurePage
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('메인 화면'),
      ),
      // bottomNavigationBar
    );
  }
}