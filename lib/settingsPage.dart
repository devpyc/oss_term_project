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

  final StreakManager _streakManager = StreakManager();
  Map<int, bool> _completedDaysMap = <int, bool>{};
  bool _isStreakLoading = true;
  int _currentStreak = 0;
  bool _isDisposed = false;

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
    _isDisposed = true;
    _workController.dispose();
    _breakController.dispose();
    customTimeController.dispose();
    customTimeController2.dispose();
    super.dispose();
  }

  _loadSettings() {
    setState(() {
      selectedSound = StaticVariableSet.selectedAlarmSound;
      customTimeController.text = (StaticVariableSet.timerTimeWork ~/ 60).toString();
      customTimeController2.text = (StaticVariableSet.timerTimeBreak ~/ 60).toString();
    });
  }

  Future<void> _loadStreakData() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isStreakLoading = true;
    });

    final daysInYear = _getDaysInCurrentYear();
    final completedMap = await _streakManager.getCompletedDaysMapForCurrentYear(daysInYear);
    final streak = await _streakManager.getCurrentStreak();

    if (!_isDisposed && mounted) {
      setState(() {
        _completedDaysMap = completedMap;
        _currentStreak = streak;
        _isStreakLoading = false;
      });
    }
  }

  _previewAlarmSound(String soundName) async {
    if (soundName == '끄기') return;

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
              trailing: Text('v1.1', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    return Column(
      children: [
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

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateTime.now().year}년',
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

        if (_isStreakLoading)
          Container(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _buildStreakCalendar(),

        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isStreakLoading ? null : _loadStreakData,
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

  Widget _buildStreakCalendar() {
    final daysInYear = _getDaysInCurrentYear();

    if (_completedDaysMap.isEmpty) {
      return Container(
        height: 120,
        child: Center(
          child: Text(
            '데이터를 불러오는 중...',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final calculatedWidth = (daysInYear * 15.0).clamp(300.0, 1200.0);

    return Container(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: StreakifyWidget(
          numberOfDays: daysInYear,
          crossAxisCount: 7,
          margin: const EdgeInsets.all(1),
          isDayTargetReachedMap: _completedDaysMap,
          height: 120,
          width: calculatedWidth,
          onTap: (index) {
            if (index >= 0 && index < daysInYear && !_isDisposed && mounted) {
              _showDayInfo(index);
            }
          },
        ),
      ),
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
    if (_isDisposed || !mounted) return;

    final now = DateTime.now();
    final currentYear = now.year;
    final startOfYear = DateTime(currentYear, 1, 1);
    final selectedDate = startOfYear.add(Duration(days: index));
    final isCompleted = _completedDaysMap[index] ?? false;

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayIndex = (selectedDate.weekday - 1).clamp(0, 6);
    final weekday = weekdays[weekdayIndex];

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
              isCompleted ? '오늘 집중을 완료했습니다!' : '아직 완료하지 않았습니다',
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

  int _getDaysInCurrentYear() {
    final now = DateTime.now();
    final currentYear = now.year;
    bool isLeapYear = (currentYear % 4 == 0 && currentYear % 100 != 0) || (currentYear % 400 == 0);
    return isLeapYear ? 366 : 365;
  }

  String _getCurrentYearRange() {
    final currentYear = DateTime.now().year;
    return '${currentYear}.01.01 ~ ${currentYear}.12.31';
  }

  int _getThisMonthCount() {
    final now = DateTime.now();
    int count = 0;

    _completedDaysMap.forEach((index, isCompleted) {
      if (isCompleted == true) {
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

  int _getThisYearCount() {
    return _completedDaysMap.values.where((completed) => completed == true).length;
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