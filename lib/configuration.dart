import 'package:flutter/material.dart';

class StaticVariableSet {
  /// 집중 시간 (seconds)
  static int timerTimeWork = 1500;
  /// 휴식 시간 (seconds)
  static int timerTimeBreak = 300;
  /// 진동 세기 (ms)
  static int vibrateStrength = 1000;
  /// 집중 시간 타이머 색
  static const Color myColorBlue = Colors.blue;
  /// 휴식 시간 타이머 색
  static const Color myColorGreen = Colors.green;
  /// 타이머 색
  static Color myTimerColor = myColorBlue;
  // static String b = "";
}