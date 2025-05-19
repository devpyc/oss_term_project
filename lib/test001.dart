import 'package:flutter/material.dart';
import 'dart:async';

class test001 extends StatefulWidget {
  // const test000({super.key, required this.title});

  // final String title;

  @override
  State<test001> createState() => test001State();
}

class test001State extends State<test001> {
  // const test000State({super.key});
  int timercho = 00;
  int timerbun = 25;
  late Timer _timer;

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timerbun == 0 && timercho == 0) {
        setState(() {
          timer.cancel();
        });
      } else if (timercho == 0) {
        timercho = 59;
        timerbun--;
      } else {
        setState(() {
          timercho--;
        });
      }
      print(timercho);
    });
  }

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
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('$timerbun' + ':' + '$timercho'),
            ElevatedButton(
              onPressed: () {
                if (!_timer.isActive) {
                  timercho = 11;
                  startTimer();
                }
              },
              child: Text(_timer.isActive ? '타이머 실행 중' : '타이머 시작')
            )
          ],
        )
      ),
    );
  }
}