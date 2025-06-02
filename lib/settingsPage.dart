import 'package:flutter/material.dart';
import 'main.dart'; // isDarkModeNotifier 때문에 추가
import 'package:streakify/streakify.dart'; // streakify 추가
import 'package:alarm/alarm.dart';
import 'main.dart';
import 'configuration.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? selectedTheme = '기본 테마';
  String? selectedSound;
  TextEditingController customTimeController = TextEditingController();
  TextEditingController customTimeController2 = TextEditingController();

  final themes = ['기본 테마', '파란 테마', '녹색 테마'];
  final sounds = ['끄기', '벨소리 1', '벨소리 2', '벨소리 3'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() {
    setState(() {
      selectedSound = StaticVariableSet.selectedAlarmSound;
      customTimeController.text = (StaticVariableSet.timerTimeWork ~/ 60).toString();
      customTimeController2.text = (StaticVariableSet.timerTimeBreak ~/ 60).toString();
    });
  }

  _previewAlarmSound(String soundName) async {
    if (soundName == '끄기') return;

    try {
      await Alarm.stop(999);

      final alarmSettings = AlarmSettings(
        id: 999,
        dateTime: DateTime.now(),
        assetAudioPath: StaticVariableSet.getAlarmSoundPath(soundName),
        loopAudio: false,
        vibrate: false,
        warningNotificationOnKill: false,
        androidFullScreenIntent: false,
        volumeSettings: VolumeSettings.fade(
          volume: 0.5,
          fadeDuration: Duration(seconds: 1),
        ),
        notificationSettings: NotificationSettings(
          title: '미리보기',
          body: soundName,
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);

      Future.delayed(Duration(seconds: 3), () {
        Alarm.stop(999);
      });

    } catch (e) {
      print('미리보기 오류: $e');
    }
  }

  final int numberOfDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          _buildSectionTitle('스트릭 (Streak)'),
          _buildCard(child: _buildStreakSection()),

          _buildSectionTitle('화면'),
          _buildCard(
            child: SwitchListTile(
              title: const Text('다크모드'),
              value: isDarkModeNotifier.value,
              onChanged: (val) {
                setState(() {
                  isDarkModeNotifier.value = val;
                });
              },
            ),
          ),
          _buildCard(
            child: ListTile(
              title: const Text('테마 설정'),
              trailing: DropdownButton<String>(
                value: selectedTheme,
                items: themes
                    .map((theme) => DropdownMenuItem(value: theme, child: Text(theme)))
                    .toList(),
                onChanged: (val) {
                  setState(() => selectedTheme = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('알림'),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '알람 소리',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedSound,
                          isExpanded: true,
                          items: sounds
                              .map((sound) => DropdownMenuItem(value: sound, child: Text(sound)))
                              .toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() => selectedSound = val);
                              await StaticVariableSet.saveAlarmSound(val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (selectedSound != null && selectedSound != '끄기')
                        ElevatedButton.icon(
                          onPressed: () => _previewAlarmSound(selectedSound!),
                          icon: Icon(Icons.play_arrow, size: 18),
                          label: Text('미리듣기'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                  if (selectedSound == '끄기')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '알람 소리가 꺼져 있습니다',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('타이머'),
          _buildCard(
            child: ListTile(
              title: const Text('집중 시간(분)'),
              subtitle: TextField(
                controller: customTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(),
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  if (minutes != null && minutes > 0) {
                    StaticVariableSet.saveTimerTimes(minutes * 60, StaticVariableSet.timerTimeBreak);
                  }
                },
              ),
            ),
          ),
          _buildCard(
            child: ListTile(
              title: const Text('휴식 시간(분)'),
              subtitle: TextField(
                controller: customTimeController2,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(),
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  if (minutes != null && minutes > 0) {
                    StaticVariableSet.saveTimerTimes(StaticVariableSet.timerTimeWork, minutes * 60);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('기타'),
          _buildCard(
            child: ListTile(
              title: const Text('오픈소스 라이선스'),
              subtitle: Text(
                '• flutter\n• provider\n• shared_preferences\n• streakify',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          _buildCard(
            child: const ListTile(
              title: Text('앱 버전'),
              trailing: Text('v1.0.0', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    return Center(
      child: StreakifyWidget(
        numberOfDays: 365,
        crossAxisCount: 7, //세로
        margin: const EdgeInsets.all(1),
        isDayTargetReachedMap: Map.fromEntries(
          List.generate(
            numberOfDays,
            (index) => MapEntry(index, index % 2 == 0 || index % 3 == 0),
          ),
        ),
        height: 100,
        width: 1050,
        onTap: (index) {
          // 날짜 박스 클릭 시 로직
          debugPrint('Day tapped: $index');
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: child,
      ),
    );
  }
}