import 'package:flutter/material.dart';

void main() {
  runApp(const PomodoroSettingsApp());
}

class PomodoroSettingsApp extends StatelessWidget {
  const PomodoroSettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Settings',
      theme: ThemeData.light(),       // 밝은 테마
      darkTheme: ThemeData.dark(),    // 다크 테마
      themeMode: ThemeMode.dark,      // 항상 다크 테마로 사용
      home: const SettingsPage(),
    );



  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int pomodoroDuration = 25;
  int shortBreak = 5;
  int longBreak = 15;
  int sessionsBeforeLongBreak = 4;
  bool isNotificationOn = true;
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildNumberSetting("집중 시간 (분)", pomodoroDuration, (value) {
            setState(() => pomodoroDuration = value);
          }),
          buildNumberSetting("짧은 휴식 (분)", shortBreak, (value) {
            setState(() => shortBreak = value);
          }),
          buildNumberSetting("긴 휴식 (분)", longBreak, (value) {
            setState(() => longBreak = value);
          }),
          buildNumberSetting("긴 휴식 전 세션 수", sessionsBeforeLongBreak, (value) {
            setState(() => sessionsBeforeLongBreak = value);
          }),
          SwitchListTile(
            title: const Text("알림음"),
            value: isNotificationOn,
            onChanged: (val) {
              setState(() => isNotificationOn = val);
            },
          ),
          SwitchListTile(
            title: const Text("다크 모드"),
            value: isDarkMode,
            onChanged: (val) {
              setState(() => isDarkMode = val);
            },
          ),
        ],
      ),
    );
  }

  Widget buildNumberSetting(String title, int value, Function(int) onChanged) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: () => onChanged(value - 1), icon: const Icon(Icons.remove)),
          Text('$value'),
          IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}
