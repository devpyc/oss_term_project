import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaticVariableSet extends ChangeNotifier {
  /// 집중 시간 인덱스
  static int timerTimeWorkIndex = 4;
  /// 휴식 시간 인덱스
  static int timerTimeBreakIndex = 0;
  /// 집중 시간 (seconds)
  static int timerTimeWork = (timerTimeWorkIndex + 1) * 5 * 60;
  /// 휴식 시간 (seconds)
  static int timerTimeBreak = (timerTimeBreakIndex + 1) * 5 * 60;
  /// 진동 세기 (ms)
  static int vibrateStrength = 1000;
  /// 집중 시간 타이머 색
  static const Color myColorBlue = Colors.blue;
  /// 휴식 시간 타이머 색
  static const Color myColorGreen = Colors.green;
  /// 타이머 색
  static Color myTimerColor = myColorBlue;

  /// 모든 설정 불러오기 (앱 시작시 호출)
  static Future<void> loadAllSettings() async {
    await loadAlarmSound();
    await loadBackgroundSound();
    await loadVibration();
    await loadTimerTimes();
  }

  /// 타이머 시간 불러오기
  static Future<void> loadTimerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    timerTimeWorkIndex = prefs.getInt(TIMER_WORK_TIME_KEY) ?? 4; // 25분
    timerTimeBreakIndex = prefs.getInt(TIMER_BREAK_TIME_KEY) ?? 0; // 5분
    timerTimeWork = (timerTimeWorkIndex + 1) * 5 * 60;
    timerTimeBreak = (timerTimeBreakIndex + 1) * 5 * 60;
  }

  /// 타이머 시간 저장
  static Future<void> saveTimerTimes(int workTimeIndex, int breakTimeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(TIMER_WORK_TIME_KEY, workTimeIndex);
    await prefs.setInt(TIMER_BREAK_TIME_KEY, breakTimeIndex);
  }

  // ===== 알람 관련 설정 =====

  /// 현재 선택된 알람 소리
  static String selectedAlarmSound = '벨소리 1';
  /// 현재 선택된 알람 소리
  static String selectedBackgroundSound = 'WhiteNoise';
  /// 현재 선택된 진동 강도
  static String selectedVibration = '보통';

  // ===== 캘린더 관련 전역 변수 =====

  /// 일정 데이터 저장 맵
  static Map<DateTime, List<Event>> events = {};
  /// 알림 ID 카운터
  static int notificationIdCounter = 1;
  /// 알림 활성화 여부
  static bool isNotificationEnabled = true;
  /// 알림 미리 알림 시간 (분)
  static int notificationAdvanceTime = 10;
  /// 기본 일정 시작 시간
  static String defaultStartTime = '09:00';
  /// 기본 일정 종료 시간
  static String defaultEndTime = '10:00';
  /// 캘린더 포맷 (month, 2weeks, week)
  static String calendarFormat = 'month';

  // ===== SharedPreferences 키 =====

  /// 일정 데이터 저장 키
  static const String EVENTS_KEY = 'calendar_events';
  /// 알림 카운터 저장 키
  static const String NOTIFICATION_COUNTER_KEY = 'notification_counter';
  /// 알림 설정 저장 키
  static const String NOTIFICATION_ENABLED_KEY = 'notification_enabled';
  /// 알림 미리 시간 저장 키
  static const String NOTIFICATION_ADVANCE_TIME_KEY = 'notification_advance_time';
  /// 기본 시작 시간 저장 키
  static const String DEFAULT_START_TIME_KEY = 'default_start_time';
  /// 기본 종료 시간 저장 키
  static const String DEFAULT_END_TIME_KEY = 'default_end_time';

  // 알람 관련 키들
  static const String ALARM_SOUND_KEY = 'alarm_sound';
  static const String BACKGROUND_SOUND_KEY = 'background_sound';
  static const String ALARM_VIBRATION_KEY = 'alarm_vibration';
  static const String TIMER_WORK_TIME_KEY = 'timer_work_time';
  static const String TIMER_BREAK_TIME_KEY = 'timer_break_time';

  // ===== 알람 설정 관련 메소드 =====

  /// 알람 소리 설정 저장
  static Future<void> saveAlarmSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ALARM_SOUND_KEY, sound);
    selectedAlarmSound = sound;
  }

  /// 알람 소리 설정 불러오기
  static Future<void> loadAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    selectedAlarmSound = prefs.getString(ALARM_SOUND_KEY) ?? '벨소리 1';
  }

  /// 배경 음악 설정 저장
  static Future<void> saveBackgroundSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BACKGROUND_SOUND_KEY, sound);
    selectedBackgroundSound = sound;
  }

  /// 배경 음악 설정 불러오기
  static Future<void> loadBackgroundSound() async {
    final prefs = await SharedPreferences.getInstance();
    selectedBackgroundSound = prefs.getString(BACKGROUND_SOUND_KEY) ?? 'WhiteNoise';
  }

  /// 진동 설정 저장
  static Future<void> saveVibration(String vibration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ALARM_VIBRATION_KEY, vibration);
    selectedVibration = vibration;
    // 진동 강도도 업데이트
    vibrateStrength = getVibrationDuration(vibration);
  }

  /// 진동 설정 불러오기
  static Future<void> loadVibration() async {
    final prefs = await SharedPreferences.getInstance();
    selectedVibration = prefs.getString(ALARM_VIBRATION_KEY) ?? '보통';
    vibrateStrength = getVibrationDuration(selectedVibration);
  }

  /// 알람 소리에 따른 파일 경로 반환
  static String getAlarmSoundPath(String soundName) {
    switch (soundName) {
      case '벨소리 1':
        return 'assets/alarm1.mp3';
      case '벨소리 2':
        return 'assets/alarm2.mp3';
      case '벨소리 3':
        return 'assets/alarm3.mp3';
      case '끄기':
      default:
        return 'assets/alarm1.mp3'; // 기본값
    }
  }

  /// 배경 음악에 따른 파일 경로 반환
  static String getBackgroundSoundPath(String soundName) {
    switch (soundName) {
      case 'WhiteNoise':
        return 'whitenoise.mp3';
      case 'Fire':
        return 'fire.mp3';
      case 'Nature':
        return 'outdoor.mp3';
      case 'Rain':
        return 'heavy-rain.mp3';
      case '끄기':
        return '';
      default:
        return 'whitenoise.mp3'; // 기본값
    }
  }

  /// 진동 강도 반환 (밀리초)
  static int getVibrationDuration(String vibration) {
    switch (vibration) {
      case '없음':
        return 0;
      case '약함':
        return 500;
      case '보통':
        return 1000;
      case '강함':
        return 2000;
      default:
        return 1000;
    }
  }
}

// Event 클래스
class Event {
  final String title;
  final String startTime;
  final String endTime;
  final int? notificationId;
  bool isCompleted;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.notificationId,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'notificationId': notificationId,
      'isCompleted': isCompleted,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      notificationId: json['notificationId'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}