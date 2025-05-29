import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:vibration/vibration.dart';
// import 'package:vibration/vibration_presets.dart';

import 'configuration.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});


  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with SingleTickerProviderStateMixin {
  static int workTimerSeconds = StaticVariableSet.timerTimework;
  static int breakTimerSeconds = StaticVariableSet.timerTimebreak;

  late AnimationController _controller;
  int _currentTimerSeconds = workTimerSeconds;
  int _currentTimerIndex = 1; // 1: 첫번째(집중시간), 2: 두번째(쉬는시간)

  bool get isRunning => _controller.isAnimating && _controller.value > 0;

  String get timerText {
    int seconds = (_currentTimerSeconds * _controller.value).floor();
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
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('타이머 종료')
          )
        );
        if (_currentTimerIndex == 1) {
          // 첫 번째 타이머가 끝나면 두 번째 타이머로 전환
          // 첫 번째 타이머 종료
          setState(() {
            _currentTimerIndex = 2;
            _currentTimerSeconds = breakTimerSeconds;
            _controller.duration = Duration(seconds: breakTimerSeconds);
            _controller.value = 1.0;
          });
          _controller.reverse(from: 1.0); // 두 번째 타이머 자동 시작
        } else if (_currentTimerIndex == 2) {
          // 두 번째 타이머 종료
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
            SleekCircularSlider(
              min: 0,
              max: _currentTimerSeconds.toDouble(),
              initialValue: _currentTimerSeconds * _controller.value,
              onChange: (double value) {
                setSliderValue(value);
                // Vibration.vibrate(duration: 30);
              },
              appearance: CircularSliderAppearance(
                size: 250,
                startAngle: 270,
                angleRange: 360,
                customColors: CustomSliderColors(
                  progressBarColor: Colors.blue,
                  trackColor: Colors.grey[300]!,
                  dotColor: Colors.blueAccent,
                ),
                infoProperties: InfoProperties(
                  mainLabelStyle: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  modifier: (double value) {
                    int seconds = value.ceil();
                    String mm = (seconds ~/ 60).toString().padLeft(2, '0');
                    String ss = (seconds % 60).toString().padLeft(2, '0');
                    return '$mm:$ss';
                  },
                ),
              ),
              innerWidget: (double value) {
                int seconds = value.ceil();
                String mm = (seconds ~/ 60).toString().padLeft(2, '0');
                String ss = (seconds % 60).toString().padLeft(2, '0');
                return Center(
                  child: Text('$mm:$ss', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                );
              },
            ),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: reset,
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                  ),
                  child: Icon(Icons.replay),
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
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                  ),
                  child: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                ),
                ElevatedButton(
                    onPressed: pause,
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                    ),
                    child: Icon(Icons.stop),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
