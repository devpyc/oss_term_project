import 'package:flutter/material.dart';
import 'main.dart'; // isDarkModeNotifier 때문에 추가
import 'streak_manager.dart'; //  streak import
import 'package:flutter/cupertino.dart'; //시간 설정 

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class TimePickerWidget extends StatefulWidget {
  final String label;
  final int initialValue;
  final Function(int) onSelected;

  const TimePickerWidget({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  final List<int> timeOptions = List.generate(24, (i) => (i + 1) * 5);
  late FixedExtentScrollController controller;

  @override
  void initState() {
    super.initState();
    final index = timeOptions.indexOf(widget.initialValue);
    controller = FixedExtentScrollController(initialItem: index >= 0 ? index : 0);
  }

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: const TextStyle(fontSize: 16)),
          SizedBox(
            height: 100,
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: 32,
              onSelectedItemChanged: (index) {
                widget.onSelected(timeOptions[index]);
              },
              children: timeOptions.map((t) => Center(child: Text('$t분'))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: child,
      ),
    );
  }
}


class _SettingsPageState extends State<SettingsPage> {
   //String? selectedTheme = '기본 테마';
  String? selectedSound = '벨소리 1';
  String? selectedVibration = '보통';
  TextEditingController customTimeController = TextEditingController(text: '25');
  TextEditingController customTimeController2 = TextEditingController(text: '5');

  // final themes = ['기본 테마', '파란 테마', '녹색 테마'];
  final sounds = ['끄기', '벨소리 1', '벨소리 2', '벨소리 3'];
  final vibrations = ['없음', '약함', '보통', '강함'];

  // streak 관련 변수 (예시로 임의 값 사용, 실제로는 streak_manager에서 관리 ㄱㄴ)
  int currentStreak = 7;
  int maxStreak = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
                    const SizedBox(height: 24),
          _buildSectionTitle('스트릭 (Streak)'),
          _buildCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '현재 스트릭',
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: List.generate(maxStreak, (index) {
                    
                    bool filled = index < currentStreak;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.circle,
                        size: 14,
                        color: filled ? Colors.lightGreenAccent : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                Text(
                  '$currentStreak / $maxStreak',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
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
          
          // _buildCard(
          //   child: ListTile(
          //     title: const Text('테마 설정'),
          //     trailing: DropdownButton<String>(
          //       value: selectedTheme,
          //       items: themes
          //           .map((theme) => DropdownMenuItem(value: theme, child: Text(theme)))
          //           .toList(),
          //       onChanged: (val) {
          //         setState(() => selectedTheme = val);
          //       },
          //     ),
          //   ),
          // ),

         
          const SizedBox(height: 24),
          _buildSectionTitle('알림'),
          _buildCard(
            child: ListTile(
              title: const Text('알람 소리'),
              trailing: DropdownButton<String>(
                value: selectedSound,
                items: sounds
                    .map((sound) => DropdownMenuItem(value: sound, child: Text(sound)))
                    .toList(),
                onChanged: (val) {
                  setState(() => selectedSound = val);
                },
              ),
            ),
          ),
          _buildCard(
            child: ListTile(
              title: const Text('진동 정도'),
              trailing: DropdownButton<String>(
                value: selectedVibration,
                items: vibrations
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (val) {
                  setState(() => selectedVibration = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('타이머'),
          _buildCard(                 // 타이머 집중시간 분 설정 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('집중 시간 (분)', style: TextStyle(fontSize: 16)),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      int value = (index + 1) * 5;
                      print('집중 시간: $value분');
                      // 여기서 값 저장 가능
                    },
                    children: List.generate(24, (i) => Center(child: Text('${(i + 1) * 5}분'))),
                  ),
                ),
              ],
            ),
          ),
          _buildCard(               //휴식시간 분 설정 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('휴식 시간 (분)', style: TextStyle(fontSize: 16)),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      int value = (index + 1) * 5;
                      print('휴식 시간: $value분');
                      // 여기서 값 저장 가능
                    },
                    children: List.generate(24, (i) => Center(child: Text('${(i + 1) * 5}분'))),
                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 24),
          _buildSectionTitle('기타'),
          _buildCard(
            child: ListTile(
              title: const Text('오픈소스 라이선스'),
              subtitle: Text(
                '• flutter\n• provider\n• shared_preferences',
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
