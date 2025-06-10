import 'package:flutter/material.dart';
import 'package:streakify/streakify.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/cupertino.dart';

import 'configuration.dart';
import 'streak_manager.dart';
import 'main.dart';

class SettingsPage extends StatefulWidget {
  final ValueChanged<int> onTimeChanged;
  const SettingsPage({required this.onTimeChanged, Key? key}) : super(key: key);

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

  late FixedExtentScrollController _workController;
  late FixedExtentScrollController _breakController;

  // 스트릭 관련 변수
  final StreakManager _streakManager = StreakManager();
  Map<int, bool> _completedDaysMap = {};
  bool _isStreakLoading = true;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _workController = FixedExtentScrollController(initialItem: StaticVariableSet.timerTimeWorkIndex);
    _breakController = FixedExtentScrollController(initialItem: StaticVariableSet.timerTimeBreakIndex);
    _loadSettings();
    _loadStreakData();
  }

  @override
  void dispose() {
    _workController.dispose();
    _breakController.dispose();
    super.dispose();
  }

  _loadSettings() {
    setState(() {
      selectedSound = StaticVariableSet.selectedAlarmSound;
      customTimeController.text = (StaticVariableSet.timerTimeWork ~/ 60).toString();
      customTimeController2.text = (StaticVariableSet.timerTimeBreak ~/ 60).toString();
    });
  }

  // 스트릭 데이터 로드
  Future<void> _loadStreakData() async {
    try {
      final daysInYear = _getDaysInCurrentYear();
      final completedMap = await _streakManager.getCompletedDaysMapForCurrentYear(daysInYear);
      final streak = await _streakManager.getCurrentStreak();

      setState(() {
        _completedDaysMap = completedMap;
        _currentStreak = streak;
        _isStreakLoading = false;
      });
    } catch (e) {
      print('스트릭 데이터 로드 오류: $e');
      setState(() {
        _isStreakLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('집중 시간 (분)', style: TextStyle(fontSize: 16)),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    scrollController: _workController,
                    itemExtent: 32,
                    onSelectedItemChanged: (index) async {
                      setState(() {
                        StaticVariableSet.timerTimeWorkIndex = index;
                        StaticVariableSet.timerTimeWork = (index + 1) * 5 * 60;
                      });
                      widget.onTimeChanged((index + 1) * 5 * 60);
                      await StaticVariableSet.saveTimerTimes(StaticVariableSet.timerTimeWorkIndex, StaticVariableSet.timerTimeBreakIndex);
                    },
                    children: List.generate(24, (i) => Center(child: Text('${(i + 1) * 5}분'))),
                  ),
                ),
              ],
            ),
          ),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('휴식 시간 (분)', style: TextStyle(fontSize: 16)),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    scrollController: _breakController,
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        StaticVariableSet.timerTimeBreakIndex = index;
                        StaticVariableSet.timerTimeBreak = (index + 1) * 5 * 60;
                      });
                      StaticVariableSet.saveTimerTimes(StaticVariableSet.timerTimeWorkIndex, StaticVariableSet.timerTimeBreakIndex);
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
    return Column(
      children: [
        // 스트릭 정보 헤더
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('현재 연속', '$_currentStreak일', Colors.orange),
              _buildStatCard('이번 달', '${_getThisMonthCount()}일', Colors.blue),
              _buildStatCard('올해', '${_getThisYearCount()}일', Colors.green),
            ],
          ),
        ),

        // 연도 표시
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateTime.now().year}년 기록',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _getCurrentYearRange(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // 로딩 상태 처리
        if (_isStreakLoading)
          Container(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else
        // 스트릭 캘린더
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: StreakifyWidget(
              numberOfDays: _getDaysInCurrentYear(),
              crossAxisCount: 7,
              margin: const EdgeInsets.all(1),
              isDayTargetReachedMap: _completedDaysMap,
              height: 120,
              width: _getDaysInCurrentYear() * 15.0,
              onTap: (index) {
                _showDayInfo(index);
              },
            ),
          ),

        // 새로고침 버튼
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _loadStreakData,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('새로고침'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDayInfo(int index) {
    final now = DateTime.now();
    final currentYear = now.year;
    final startOfYear = DateTime(currentYear, 1, 1);
    final selectedDate = startOfYear.add(Duration(days: index));
    final isCompleted = _completedDaysMap[index] ?? false;

    // 요일 표시를 위한 배열
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[selectedDate.weekday - 1];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일 ($weekday)',
          style: TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.cancel,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              isCompleted ? '집중 시간을 완료했습니다!' : '아직 완료하지 않았습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isCompleted ? Colors.green : Colors.grey[600],
              ),
            ),
            if (selectedDate.isAfter(DateTime.now()))
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '(미래 날짜)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // 현재 연도의 총 일수 계산
  int _getDaysInCurrentYear() {
    final now = DateTime.now();
    final currentYear = now.year;

    // 윤년 확인
    bool isLeapYear = (currentYear % 4 == 0 && currentYear % 100 != 0) || (currentYear % 400 == 0);
    return isLeapYear ? 366 : 365;
  }

  // 현재 연도 범위 표시
  String _getCurrentYearRange() {
    final currentYear = DateTime.now().year;
    return '${currentYear}.01.01 ~ ${currentYear}.12.31';
  }

  // 이번 달 카운트
  int _getThisMonthCount() {
    final now = DateTime.now();
    int count = 0;

    _completedDaysMap.forEach((index, isCompleted) {
      if (isCompleted) {
        final currentYear = now.year;
        final startOfYear = DateTime(currentYear, 1, 1);
        final date = startOfYear.add(Duration(days: index));
        if (date.month == now.month && date.year == now.year) {
          count++;
        }
      }
    });

    return count;
  }

  // 올해 전체 카운트
  int _getThisYearCount() {
    return _completedDaysMap.values.where((completed) => completed).length;
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