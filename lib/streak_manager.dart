import 'package:shared_preferences/shared_preferences.dart';

class StreakManager {
  static const String _lastCompletedDateKey = 'last_completed_date';
  static const String _currentStreakKey = 'current_streak';

  Future<void> updateStreakIfCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDateString = prefs.getString(_lastCompletedDateKey);
    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;

    if (lastDateString != null) {
      final lastDate = DateTime.parse(lastDateString);

      final yesterday = today.subtract(Duration(days: 1));

      if (lastDate == today) {
        // 이미 오늘 완료
        return;
      } else if (lastDate == yesterday) {
        // 어제 완료한 경우 → 스트릭 증가
        currentStreak++;
      } else {
        // 연속 실패 → 스트릭 초기화
        currentStreak = 1;
      }
    } else {
      // 첫 완료
      currentStreak = 1;
    }

    await prefs.setString(_lastCompletedDateKey, today.toIso8601String());
    await prefs.setInt(_currentStreakKey, currentStreak);
  }

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCompletedDateKey);
    await prefs.setInt(_currentStreakKey, 0);
  }
}
