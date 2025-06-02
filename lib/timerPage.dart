import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:vibration/vibration.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:alarm/alarm.dart'; // 수정된 import
import 'dart:io';
import 'configuration.dart';
import 'notification.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});
  
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with SingleTickerProviderStateMixin {
  static int workTimerSeconds = StaticVariableSet.timerTimeWork;
  static int breakTimerSeconds = StaticVariableSet.timerTimeBreak;

  late AnimationController _controller;
  int _currentTimerSeconds = workTimerSeconds;
  int _currentTimerIndex = 1;

  static const int alarmId = 1; // 알람 ID

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
        // 타이머 완료 시 알람 울리기
        await _playAlarm();

        if (_currentTimerIndex == 1) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CountdownDialog(
              onConfirm: () {
                _stopAlarm(); // 알람 정지
                setState(() {
                  _currentTimerIndex = 2;
                  _currentTimerSeconds = breakTimerSeconds;
                  _controller.duration = Duration(seconds: breakTimerSeconds);
                  _controller.value = 1.0;
                  StaticVariableSet.myTimerColor = StaticVariableSet.myColorGreen;
                });
                _controller.reverse(from: 1.0);
              },
              onTimeout: () {
                _stopAlarm(); // 알람 정지
                reset();
              },
            ),
          );
        } else if (_currentTimerIndex == 2) {
          FlutterLocalNotification.showNotification();
          // 3초 후 알람 자동 정지
          Future.delayed(Duration(seconds: 3), () {
            _stopAlarm();
          });
          reset();
        }
      }
    });
  }

  // TimerPage의 _playAlarm() 메소드를 다시 원래대로
  Future<void> _playAlarm() async {
    try {
      final alarmSettings = AlarmSettings(
        id: alarmId,
        dateTime: DateTime.now(),
        assetAudioPath: 'assets/alarm1.mp3', // 일단 고정으로 테스트
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          volume: 0.8,
          fadeDuration: Duration(seconds: 3),
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: '타이머 완료!',
          body: _currentTimerIndex == 1 ? '집중 시간이 끝났습니다!' : '휴식 시간이 끝났습니다!',
          stopButton: '정지',
          icon: 'notification_icon',
          iconColor: Color(0xff862778),
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      print('알람 설정 오류: $e');
      Vibration.vibrate(duration: 2000);
    }
  }

  // 알람 정지
  void _stopAlarm() async {
    try {
      await Alarm.stop(alarmId);
    } catch (e) {
      print('알람 정지 오류: $e');
    }
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
    _stopAlarm(); // 리셋 시 알람도 정지
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
    _stopAlarm(); // 위젯 해제 시 알람 정지
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
            // 기존 UI 코드와 동일
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

// CountdownDialog는 기존과 동일
class CountdownDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onTimeout;

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
        widget.onTimeout();
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