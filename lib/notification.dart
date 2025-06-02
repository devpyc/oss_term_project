import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'main.dart';
import 'configuration.dart'; // 전역 변수 import
import 'dart:io' show Platform;

// 안드로이드 관련 설정은 주석 처리 (어차피 안드로이드 권한 파일도 수정하지 않았음)

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // 백그라운드에서 알림 클릭 시 동작
}

class FlutterLocalNotification {
  FlutterLocalNotification._();

  static init() async {
    // AndroidInitializationSettings androidInitializationSettings = const AndroidInitializationSettings('mipmap/ic_launcher');

    DarwinInitializationSettings iosInitializationSettings = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    InitializationSettings initializationSettings = InitializationSettings(
      // android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알릭 시 동작 정의
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static requestNotificationPermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> showNotification() async {
    // const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    //   'channel id',
    //   'channel name',
    //   channelDescription: 'channel description',
    //   importance: Importance.max,
    //   priority: Priority.max,
    //   showWhen: false
    // );

    const NotificationDetails notificationDetails = NotificationDetails(
      // android: androidNotificationDetails,
      // iOS: DarwinNotificationDetails(badgeNumber: 1, sound: '')
        iOS: DarwinNotificationDetails()
    );

    await flutterLocalNotificationsPlugin.show(
        0,
        '알림',
        '휴식 시간이 종료되었습니다. 다시 집중하세요!',
        notificationDetails,
        payload: "HELLOWORLD"
    );
  }

  //! Foreground 상태(앱이 열린 상태에서 받은 경우)
  static void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    //! Payload(전송 데이터)를 Stream에 추가합니다.
    final String payload = notificationResponse.payload ?? "";
    if (notificationResponse.payload != null || notificationResponse.payload!.isNotEmpty) {
      print('FOREGROUND PAYLOAD: $payload');
      streamController.add(payload);
    }
  }

  //! Background 상태(앱이 닫힌 상태에서 받은 경우)
  static void onBackgroundNotificationResponse() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
    await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    //! 앱이 Notification을 통해서 열린 경우라면 Payload(전송 데이터)를 Stream에 추가합니다.
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      String payload =
          notificationAppLaunchDetails!.notificationResponse?.payload ?? "";
      print("BACKGROUND PAYLOAD: $payload");
      streamController.add(payload);
    }
  }
}

// ===== 캘린더용 알림 클래스 (새로 추가) =====
class CalendarNotification {
  CalendarNotification._();

  // 캘린더용 초기화 (타임존 포함)
  static Future<void> initCalendar() async {
    // iOS에서만 실행
    if (!Platform.isIOS) return;

    // 타임존 초기화
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  }

  // 캘린더 일정 예약 알림
  static Future<void> scheduleEventNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // iOS에서만 실행
    if (!Platform.isIOS) return;

    // 전역 변수에서 알림 활성화 여부 확인
    if (!StaticVariableSet.isNotificationEnabled) {
      return;
    }

    // 과거 시간인지 확인
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    const NotificationDetails notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      payload: 'calendar_event_$id',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 특정 알림 취소
  static Future<void> cancelNotification(int id) async {
    if (!Platform.isIOS) return;
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    if (!Platform.isIOS) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // 예약된 알림 목록 확인 (디버깅용)
  static Future<void> checkPendingNotifications() async {
    if (!Platform.isIOS) return;
    final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    // 디버깅용 출력은 필요시 추가
  }

  // 일정 알림 예약 (Event 객체와 날짜를 받아서 처리)
  static Future<void> scheduleEventWithDate(Event event, DateTime eventDate) async {
    if (!Platform.isIOS) return;
    if (event.notificationId == null) return;

    final timeParts = event.startTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final eventDateTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      hour,
      minute,
    );

    // 전역 변수에서 미리 알림 시간 가져오기
    final notificationTime = eventDateTime.subtract(
        Duration(minutes: StaticVariableSet.notificationAdvanceTime)
    );

    await scheduleEventNotification(
      id: event.notificationId!,
      title: '일정 알림',
      body: '${event.title} (${StaticVariableSet.notificationAdvanceTime}분 후 시작)',
      scheduledTime: notificationTime,
    );
  }
}