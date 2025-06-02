import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'configuration.dart'; // 전역 변수 import
import 'notification.dart'; // 수정된 notification import

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeNotifications();
    await _loadEvents();
    await _loadNotificationCounter();
    await _rescheduleNotifications(); // 앱 재시작 시 알림 재예약
  }

  Future<void> _initializeNotifications() async {
    await CalendarNotification.initCalendar();
  }

  // 알림 카운터 로드
  Future<void> _loadNotificationCounter() async {
    final prefs = await SharedPreferences.getInstance();
    StaticVariableSet.notificationIdCounter = prefs.getInt(StaticVariableSet.NOTIFICATION_COUNTER_KEY) ?? 1;
  }

  // 알림 카운터 저장
  Future<void> _saveNotificationCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StaticVariableSet.NOTIFICATION_COUNTER_KEY, StaticVariableSet.notificationIdCounter);
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(StaticVariableSet.EVENTS_KEY);

    if (eventsJson != null) {
      final Map<String, dynamic> eventsMap = json.decode(eventsJson);

      eventsMap.forEach((dateString, eventsList) {
        final date = DateTime.parse(dateString);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final events = (eventsList as List)
            .map((eventJson) => Event.fromJson(eventJson))
            .toList();
        StaticVariableSet.events[normalizedDate] = events;
      });

      setState(() {});
    }
  }

  // 로컬에 일정 저장
  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> eventsMap = {};
    StaticVariableSet.events.forEach((date, events) {
      eventsMap[date.toIso8601String()] =
          events.map((event) => event.toJson()).toList();
    });

    await prefs.setString(StaticVariableSet.EVENTS_KEY, json.encode(eventsMap));
  }

  // 앱 재시작 시 알림 재예약
  Future<void> _rescheduleNotifications() async {
    for (final entry in StaticVariableSet.events.entries) {
      final date = entry.key;
      final events = entry.value;

      for (final event in events) {
        if (!event.isCompleted && event.notificationId != null) {
          await CalendarNotification.scheduleEventWithDate(event, date);
        }
      }
    }
  }

  // 선택한 날짜 일정 불러오기
  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return StaticVariableSet.events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          // 테스트 알림 버튼
          IconButton(
            icon: const Icon(Icons.notification_important),
            onPressed: () async {
              await CalendarNotification.scheduleEventNotification(
                id: 999,
                title: 'Test',
                body: '테스트 알림입니다',
                scheduledTime: DateTime.now().add(const Duration(seconds: 10)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('10초 후 테스트 알림 표시')),
              );
            },
          ),
          // 예약된 알림 확인 버튼
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () async {
              await CalendarNotification.checkPendingNotifications();
            },
          ),
          // 데이터 초기화 메뉴
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('초기화'),
                    content: const Text('모든 일정 데이터를 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  await CalendarNotification.cancelAllNotifications();
                  setState(() {
                    StaticVariableSet.events.clear();
                    StaticVariableSet.notificationIdCounter = 1;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 데이터가 삭제되었습니다.')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever),
                    SizedBox(width: 8),
                    Text('데이터 초기화'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showAddEventDialog(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return const Center(
        child: Text('일정 없음'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: ListTile(
            leading: Checkbox(
              value: event.isCompleted,
              onChanged: (value) async {
                setState(() {
                  event.isCompleted = value!;
                });

                // 완료된 일정의 알림을 취소
                if (event.isCompleted && event.notificationId != null) {
                  await CalendarNotification.cancelNotification(event.notificationId!);
                } else if (!event.isCompleted && event.notificationId != null) {
                  // 완료 취소 시 알림 재예약
                  await CalendarNotification.scheduleEventWithDate(event, _selectedDay!);
                }

                await _saveEvents();
              },
            ),
            title: Text(
              event.title,
              style: TextStyle(
                decoration: event.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: event.isCompleted
                    ? Colors.grey
                    : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${event.startTime} - ${event.endTime}'),
                if (event.notificationId != null)
                  Text(
                    '알림 ID: ${event.notificationId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // 알림 취소
                if (event.notificationId != null) {
                  await CalendarNotification.cancelNotification(event.notificationId!);
                }

                setState(() {
                  _getEventsForDay(_selectedDay!).remove(event);
                });
                await _saveEvents();
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog(DateTime day) {
    final titleController = TextEditingController();

    String startTime = StaticVariableSet.defaultStartTime;
    String endTime = StaticVariableSet.defaultEndTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${DateFormat('yyyy-MM-dd').format(day)} 일정 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '일정 제목',
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  ListTile(
                    title: const Text('시작 시간'),
                    subtitle: Text(startTime),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () {
                      _showTimeSelectionDialog(context, startTime, (selectedTime) {
                        setDialogState(() {
                          startTime = selectedTime;
                        });
                      });
                    },
                  ),

                  ListTile(
                    title: const Text('종료 시간'),
                    subtitle: Text(endTime),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () {
                      _showTimeSelectionDialog(context, endTime, (selectedTime) {
                        setDialogState(() {
                          endTime = selectedTime;
                        });
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final normalizedDay = DateTime(day.year, day.month, day.day);

                      if (StaticVariableSet.events[normalizedDay] == null) {
                        StaticVariableSet.events[normalizedDay] = [];
                      }

                      final newEvent = Event(
                        title: titleController.text,
                        startTime: startTime,
                        endTime: endTime,
                        notificationId: StaticVariableSet.notificationIdCounter++,
                      );

                      setState(() {
                        StaticVariableSet.events[normalizedDay]!.add(newEvent);
                      });

                      // 알림 예약
                      await CalendarNotification.scheduleEventWithDate(newEvent, normalizedDay);

                      await _saveEvents();
                      await _saveNotificationCounter();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('일정이 추가되고 알림이 예약되었습니다.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTimeSelectionDialog(
      BuildContext context,
      String currentTime,
      Function(String) onTimeSelected
      ) {
    // 현재 시간 파싱
    final parts = currentTime.split(':');
    int currentHour = int.parse(parts[0]);
    int currentMinute = int.parse(parts[1]);

    List<int> hours = List.generate(24, (index) => index);
    List<int> minutes = List.generate(12, (index) => index * 5);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('시간 선택'),
              content: SizedBox(
                width: double.maxFinite,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('시', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: hours.length,
                              itemBuilder: (context, index) {
                                final hour = hours[index];
                                final isSelected = hour == currentHour;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      currentHour = hour;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.blue.withOpacity(0.2) : null,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        hour.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.blue : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),
                    const Text(':', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('분', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: minutes.length,
                              itemBuilder: (context, index) {
                                final minute = minutes[index];
                                final isSelected = minute == currentMinute;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      currentMinute = minute;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.blue.withOpacity(0.2) : null,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        minute.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.blue : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    final selectedTime = '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}';
                    onTimeSelected(selectedTime);
                    Navigator.pop(context);
                  },
                  child: const Text('선택'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}