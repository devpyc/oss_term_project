import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
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
          // 일정 목록 위젯
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
              onChanged: _selectedDay!.isBefore(DateTime.now())
                  ? (value) {
                setState(() {
                  event.isCompleted = value!;
                });
              }
                  : null,
            ),
            title: Text(event.title),
            subtitle: Text('${event.startTime} - ${event.endTime}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _getEventsForDay(_selectedDay!).remove(event);
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog(DateTime day) {
    final titleController = TextEditingController();

    String startTime = '09:00';
    String endTime = '10:00';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                ),
              ),
              const SizedBox(height: 16.0),

              ListTile(
                title: const Text('시작 시간'),
                subtitle: Text(startTime),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () {
                  _showTimeSelectionDialog(context, startTime, (selectedTime) {
                    setState(() {
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
                    setState(() {
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
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final normalizedDay = DateTime(day.year, day.month, day.day);

                  if (_events[normalizedDay] == null) {
                    _events[normalizedDay] = [];
                  }

                  setState(() {
                    _events[normalizedDay]!.add(
                      Event(
                        title: titleController.text,
                        startTime: startTime,
                        endTime: endTime,
                      ),
                    );
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _showTimeSelectionDialog(
      BuildContext context,
      String currentTime,
      Function(String) onTimeSelected
      ) {

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
              content: Container(
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
                          Container(
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
                          Container(
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

class Event {
  final String title;
  final String startTime;
  final String endTime;
  bool isCompleted;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
  });
}