import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main.dart';

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