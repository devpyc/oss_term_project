import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:vibration/vibration.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:alarm/alarm.dart';
import 'configuration.dart';
import 'notification.dart';
import 'streak_manager.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  int _currentTimerSeconds = StaticVariableSet.timerTimeWork;
  int _currentTimerIndex = 1;
  bool _isDisposed = false;
  Timer? _alarmTimer;
  bool _alarmIsPlaying = false;

  final StreakManager _streakManager = StreakManager();
  static const int alarmId = 1;

  final player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playerCompleteSubscription;

  bool get isRunning => _controller.isAnimating && _controller.value > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 생명주기 관찰자 추가

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: StaticVariableSet.timerTimeWork),
    );
    _controller.value = 1.0;

    _controller.addListener(_onControllerUpdate);
    _controller.addStatusListener(_onStatusChanged);

    // AudioPlayer 상태 리스너 설정
    _playerStateSubscription = player.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });
  }

  void _onControllerUpdate() {
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  void _onStatusChanged(AnimationStatus status) async {
    if (_isDisposed || !mounted) return;

    if (status == AnimationStatus.dismissed) {
      await _handleTimerComplete();
    }
  }

  Future<void> _handleTimerComplete() async {
    if (_isDisposed || !mounted) return;

    try {
      await _playAlarmSafely();

      if (_currentTimerIndex == 1) {
        // 집중 시간 완료 - 스트릭 업데이트는 확인 버튼 클릭 시에만
        if (!_isDisposed && mounted) {
          await _showCompletionDialog();
        }
      } else if (_currentTimerIndex == 2) {
        // 휴식 시간 완료
        FlutterLocalNotification.showNotification();
        await Future.delayed(Duration(seconds: 2));
        if (!_isDisposed && mounted) {
          _stopAlarmSafely();
          reset();
        }
      }
    } catch (e) {
      print('타이머 완료 처리 오류: $e');
      if (!_isDisposed && mounted) {
        _fallbackVibration();
      }
    }
  }

  Future<void> _playAlarmSafely() async {
    if (_isDisposed || !mounted || _alarmIsPlaying) return;

    try {
      _alarmIsPlaying = true;

      // 기존 알람 정리
      await _stopAlarmSafely();
      await Future.delayed(Duration(milliseconds: 100)); // 짧은 지연

      if (_isDisposed || !mounted) return;

      // 실제 디바이스에서는 더 단순한 설정 사용
      final alarmSettings = AlarmSettings(
        id: alarmId,
        dateTime: DateTime.now(),
        assetAudioPath: 'assets/alarm1.mp3', // 고정 경로 사용 (더 안전)
        loopAudio: false,
        vibrate: true,
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: false, // iOS에서는 false
        volumeSettings: VolumeSettings.fade(
          volume: 0.7, // fade 대신 고정 볼륨
          fadeDuration: Duration(seconds: 1),
        ),
        notificationSettings: NotificationSettings(
          title: '타이머 완료',
          body: _currentTimerIndex == 1 ? '집중 완료!' : '휴식 완료!',
          stopButton: '정지',
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);

      _alarmTimer = Timer(Duration(seconds: 10), () {
        if (!_isDisposed && mounted) {
          _stopAlarmSafely();
        }
      });

    } catch (e) {
      print('알람 재생 오류: $e');
      _alarmIsPlaying = false;
      _fallbackVibration();
    }
  }

  Future<void> _stopAlarmSafely() async {
    try {
      _alarmTimer?.cancel();
      _alarmTimer = null;

      if (await Alarm.isRinging(alarmId)) {
        await Alarm.stop(alarmId);
      }

      _alarmIsPlaying = false;
    } catch (e) {
      print('알람 정지 오류: $e');
      _alarmIsPlaying = false;
    }
  }

  void _fallbackVibration() {
    try {
      Vibration.vibrate(
        duration: 500,
        amplitude: 128,
      );
    } catch (e) {
      print('진동 오류: $e');
    }
  }

  Future<void> _showCompletionDialog() async {
    if (_isDisposed || !mounted) return;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CountdownDialog(
          onConfirm: () async { // async 추가
            _stopAlarmSafely();

            // 확인 버튼 클릭 시에만 스트릭 업데이트
            try {
              await _streakManager.updateStreakIfCompletedToday();
              print('스트릭이 업데이트되었습니다!');
            } catch (e) {
              print('스트릭 업데이트 오류: $e');
            }

            if (!_isDisposed && mounted) {
              setState(() {
                _currentTimerIndex = 2;
                _currentTimerSeconds = StaticVariableSet.timerTimeBreak;
                _controller.duration = Duration(seconds: StaticVariableSet.timerTimeBreak);
                _controller.value = 1.0;
                StaticVariableSet.myTimerColor = StaticVariableSet.myColorGreen;
              });
              _controller.reverse(from: 1.0);
            }
          },
          onTimeout: () {
            // 시간 초과 시에는 스트릭 업데이트 없음
            _stopAlarmSafely();
            reset();
            print('시간 초과로 스트릭이 업데이트되지 않았습니다.');
          },
        ),
      );
    } catch (e) {
      print('다이얼로그 표시 오류: $e');
      _stopAlarmSafely();
      reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      // 앱이 백그라운드로 갈 때 알람 정리
        _stopAlarmSafely();
        break;
      case AppLifecycleState.resumed:
      // 앱이 포그라운드로 올 때
        break;
      case AppLifecycleState.detached:
      // 앱 종료 시
        _cleanup();
        break;
      default:
        break;
    }
  }

  Future<void> _cleanup() async {
    _isDisposed = true;
    _alarmTimer?.cancel();
    await _stopAlarmSafely();
    _controller.removeListener(_onControllerUpdate);
    _controller.removeStatusListener(_onStatusChanged);

    // AudioPlayer 정리
    await player.stop();
    await _playerStateSubscription?.cancel();
    await _playerCompleteSubscription?.cancel();
  }

  // 집중 시간에만 배경 음악 재생 및 일시정지 후 다시 재생 시 이어서 재생
  void startBackgroundSound() async {
    if (_currentTimerIndex == 1) {
      try {
        if (_playerState == PlayerState.stopped) {
          await player.play(AssetSource(StaticVariableSet.getBackgroundSoundPath(StaticVariableSet.selectedBackgroundSound)));
        } else if (_playerState == PlayerState.paused) {
          await player.resume();
        } else {
          await player.play(AssetSource(StaticVariableSet.getBackgroundSoundPath(StaticVariableSet.selectedBackgroundSound)));
        }
      } catch (e) {
        print('배경음 재생 오류: $e');
      }
    }
  }

  // 반복 재생 설정
  void loopBackgroundSound() {
    _playerCompleteSubscription?.cancel();
    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      if (_currentTimerIndex == 1 && isRunning) {
        startBackgroundSound(); // 파일이 끝나면 다시 재생
      }
    });
  }

  void start() async {
    if (_isDisposed || !mounted || _controller.isAnimating) return;

    _controller.reverse(from: _controller.value);
    startBackgroundSound();
    loopBackgroundSound();
    setState(() {});
  }

  void pause() {
    if (_isDisposed || !mounted) return;
    if (_controller.isAnimating) {
      _controller.stop();
      player.pause();
      setState(() {});
    }
  }

  void reset() {
    if (_isDisposed || !mounted) return;

    _controller.stop();
    _stopAlarmSafely();

    // 리셋 시 배경음도 정지
    player.stop();

    setState(() {
      _currentTimerIndex = 1;
      _currentTimerSeconds = StaticVariableSet.timerTimeWork;
      _controller.duration = Duration(seconds: StaticVariableSet.timerTimeWork);
      _controller.value = 1.0;
      StaticVariableSet.myTimerColor = StaticVariableSet.myColorBlue;
    });
  }

  void setSliderValue(double value) {
    if (_isDisposed || !mounted) return;
    _controller.stop();
    _controller.value = value / _currentTimerSeconds;
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    _controller.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _currentTimerIndex == 1 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _currentTimerIndex == 1 ? Colors.orange : Colors.green,
                  width: 2,
                ),
              ),
              child: Text(
                _currentTimerIndex == 1 ? '집중 시간' : '휴식 시간',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _currentTimerIndex == 1 ? Colors.orange : Colors.green,
                ),
              ),
            ),

            SleekCircularSlider(
              min: 0,
              max: _currentTimerSeconds.toDouble(),
              initialValue: _currentTimerSeconds * _controller.value,
              onChange: setSliderValue,
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
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    );
    _controller.forward();
    _controller.addListener(_onUpdate);
    _controller.addStatusListener(_onStatusChanged);
  }

  void _onUpdate() {
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  void _onStatusChanged(AnimationStatus status) {
    if (_isDisposed || !mounted) return;
    if (status == AnimationStatus.completed && !_confirmed) {
      Navigator.of(context, rootNavigator: true).pop();
      widget.onTimeout();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.removeListener(_onUpdate);
    _controller.removeStatusListener(_onStatusChanged);
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
      title: Text('🎉 집중 시간 완료!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '축하합니다!\n집중 시간을 완료했습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            '확인을 누르면 스트릭이 기록되고\n휴식 시간이 시작됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 10),
          Text(
            '남은 시간: $secondsLeft초',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _confirmed = true;
            Navigator.of(context, rootNavigator: true).pop();
            widget.onConfirm();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text('확인'),
        ),
      ],
    );
  }
}