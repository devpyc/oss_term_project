import 'package:shared_preferences/shared_preferences.dart';

class StreakManager {
  static const String _currentStreakKey = 'current_streak';
  static const String _lastCompletedDateKey = 'last_completed_date';
  static const String _completedDatesKey = 'completed_dates';

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  Future<void> updateStreakIfCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDateString = prefs.getString(_lastCompletedDateKey);
    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;

    List<String> completedDates = prefs.getStringList(_completedDatesKey) ?? <String>[];
    String todayString = today.toIso8601String();

    bool alreadyCompletedToday = completedDates.contains(todayString);

    if (lastDateString != null) {
      final lastDate = DateTime.parse(lastDateString);
      final yesterday = today.subtract(Duration(days: 1));

      if (lastDate == today && alreadyCompletedToday) {
        return;
      } else if (lastDate == yesterday || lastDate == today) {
        if (!alreadyCompletedToday) {
          currentStreak++;
        }
      } else {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    if (!alreadyCompletedToday) {
      completedDates.add(todayString);
      await prefs.setStringList(_completedDatesKey, completedDates);
      await prefs.setString(_lastCompletedDateKey, today.toIso8601String());
      await prefs.setInt(_currentStreakKey, currentStreak);
    }
  }

  Future<Map<int, bool>> getCompletedDaysMapForCurrentYear(int daysInYear) async {
    final prefs = await SharedPreferences.getInstance();
    final completedDates = prefs.getStringList(_completedDatesKey) ?? <String>[];

    Map<int, bool> completedMap = <int, bool>{};
    final now = DateTime.now();
    final currentYear = now.year;
    final startOfYear = DateTime(currentYear, 1, 1);

    for (int i = 0; i < daysInYear; i++) {
      final date = startOfYear.add(Duration(days: i));
      final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
      completedMap[i] = completedDates.contains(dateString);
    }

    return completedMap;
  }

  Future<Map<int, bool>> getCompletedDaysMap(int numberOfDays) async {
    final prefs = await SharedPreferences.getInstance();
    final completedDates = prefs.getStringList(_completedDatesKey) ?? <String>[];

    Map<int, bool> completedMap = <int, bool>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < numberOfDays; i++) {
      final date = today.subtract(Duration(days: numberOfDays - 1 - i));
      final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
      completedMap[i] = completedDates.contains(dateString);
    }

    return completedMap;
  }

  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_lastCompletedDateKey);
    await prefs.remove(_completedDatesKey);
  }

  Future<bool> isDateCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final completedDates = prefs.getStringList(_completedDatesKey) ?? <String>[];
    final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
    return completedDates.contains(dateString);
  }

  Future<int> getTotalCompletedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final completedDates = prefs.getStringList(_completedDatesKey) ?? <String>[];
    return completedDates.length;
  }
}