import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:vibration/vibration.dart';
// import 'package:vibration/vibration_presets.dart';
import 'package:avatar_glow/avatar_glow.dart';

import 'configuration.dart';
import 'notification.dart';

class TimerPage extends StatefulWidget {

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with SingleTickerProviderStateMixin {
  static int workTimerSeconds = StaticVariableSet.timerTimeWork;
  static int breakTimerSeconds = StaticVariableSet.timerTimeBreak;

  late AnimationController _controller;
  int _currentTimerSeconds = workTimerSeconds;
  int _currentTimerIndex = 1; // 1: 첫번째(집중시간), 2: 두번째(쉬는시간)

  bool get isRunning => _controller.isAnimating && _controller.value > 0;

  String get timerText {
    int seconds = (_currentTimerSeconds * _controller.value).round();
    if (seconds < 0) seconds = 0;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: workTimerSeconds),
    );
    _controller.value = 1.0;
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.dismissed) {
        // 첫 번째, 두 번째 타이머 종료
        Vibration.vibrate(duration: 1000);
        if (_currentTimerIndex == 1) {
          // 첫 번째 타이머 종료: 팝업창 출력, 확인 클릭하면 두 번째 타이머 시작
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CountdownDialog(
              onConfirm: () {
                setState(() {
                  _currentTimerIndex = 2;
                  _currentTimerSeconds = breakTimerSeconds;
                  _controller.duration = Duration(seconds: breakTimerSeconds);
                  _controller.value = 1.0;
                  StaticVariableSet.myTimerColor = StaticVariableSet.myColorGreen;
                });
                _controller.reverse(from: 1.0); // 두 번째 타이머 시작
              },
              onTimeout: () {
                reset(); // 10초 내에 확인을 누르지 않으면 reset
              },
            ),
          );
        } else if (_currentTimerIndex == 2) {
          // 두 번째 타이머 종료
          FlutterLocalNotification.showNotification();
          reset();
        }
      }
    });
  }

  void start() {
    if (_controller.isAnimating) return;
    _controller.reverse(from: _controller.value);
    setState(() {});
  }

  void pause() {
    if (_controller.isAnimating) {
      _controller.stop();
      setState(() {});
    }
  }

  void reset() {
    _controller.stop();
    setState(() {
      _currentTimerIndex = 1;
      _currentTimerSeconds = workTimerSeconds;
      _controller.duration = Duration(seconds: workTimerSeconds);
      _controller.value = 1.0;
      StaticVariableSet.myTimerColor = StaticVariableSet.myColorBlue;
    });
  }

  void setSliderValue(double value) {
    _controller.stop();
    _controller.value = value / _currentTimerSeconds;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 타이머
            SleekCircularSlider(
              min: 0,
              max: _currentTimerSeconds.toDouble(),
              initialValue: _currentTimerSeconds * _controller.value,
              onChange: (double value) {
                setSliderValue(value);
                Vibration.vibrate(duration: 30);
              },
              appearance: CircularSliderAppearance(
                size: 250,
                startAngle: 270,
                angleRange: 360,
                customColors: CustomSliderColors(
                  progressBarColor: StaticVariableSet.myTimerColor,
                  trackColor: Colors.grey[300]!,
                  dotColor: Colors.redAccent,
                ),
              ),
              innerWidget: (double value) {
                int seconds = (_currentTimerSeconds * _controller.value).round();
                if (seconds < 0) seconds = 0;
                String mm = (seconds ~/ 60).toString().padLeft(2, '0');
                String ss = (seconds % 60).toString().padLeft(2, '0');
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    AvatarGlow(
                      // startDelay: const Duration(milliseconds: 2000),
                      duration: Duration(milliseconds: 1500),
                      repeat: true,
                      glowColor: StaticVariableSet.myTimerColor,
                      glowShape: BoxShape.circle,
                      animate: isRunning,
                      curve: Curves.fastOutSlowIn,
                      glowRadiusFactor: 0.3,
                      glowCount: 3,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(""),
                        radius: 100.0,
                      )
                    ),
                    Center(
                      child: Text(
                        '$mm:$ss',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 50),
            // 버튼 초기화, 재생 및 일시정지, 중지
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: reset,
                  child: Icon(Icons.replay),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isRunning) {
                      pause();
                    } else {
                      start();
                    }
                    setState(() {});
                  },
                  child: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                  ),
                ),
                ElevatedButton(
                  onPressed: pause,
                  child: Icon(Icons.stop),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 팝업창 출력
class CountdownDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onTimeout; // 추가

  const CountdownDialog({
    Key? key,
    required this.onConfirm,
    required this.onTimeout,
  }) : super(key: key);

  @override
  State<CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<CountdownDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    );
    if (_controller.value == 0.0) {
      _controller.forward();
    }
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_confirmed) {
        Navigator.of(context, rootNavigator: true).pop();
        widget.onTimeout(); // 10초 경과시 콜백 실행
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get secondsLeft {
    int left = 10 - (_controller.value * 10).floor();
    return left > 0 ? left : 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('알림'),
      content: Text('10초 내에 확인을 누르세요!\n남은 시간: $secondsLeft초'),
      actions: [
        TextButton(
          onPressed: () {
            _confirmed = true;
            Navigator.of(context, rootNavigator: true).pop();
            widget.onConfirm();
          },
          child: Text('확인'),
        ),
      ],
    );
  }
}


