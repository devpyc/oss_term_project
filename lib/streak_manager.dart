import 'package:shared_preferences/shared_preferences.dart';

class StreakManager {
  // SharedPreferences 키들
  static const String _currentStreakKey = 'current_streak';
  static const String _lastCompletedDateKey = 'last_completed_date';
  static const String _completedDatesKey = 'completed_dates'; // 이 줄 추가

  // 현재 스트릭 가져오기
  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  // 오늘 완료 시 스트릭 업데이트
  Future<void> updateStreakIfCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDateString = prefs.getString(_lastCompletedDateKey);
    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;

    // 완료 날짜 가져오기
    List<String> completedDates = prefs.getStringList(_completedDatesKey) ?? [];
    String todayString = today.toIso8601String();

    // 이미 오늘 완료했는지 확인
    bool alreadyCompletedToday = completedDates.contains(todayString);

    if (lastDateString != null) {
      final lastDate = DateTime.parse(lastDateString);
      final yesterday = today.subtract(Duration(days: 1));

      if (lastDate == today && alreadyCompletedToday) {
        // 이미 오늘 완료 - 아무것도 하지 않음
        print('이미 오늘 완료됨');
        return;
      } else if (lastDate == yesterday || lastDate == today) {
        // 어제 완료하거나 오늘 첫 완료 → 스트릭 증가
        if (!alreadyCompletedToday) {
          currentStreak++;
        }
      } else {
        // 연속 실패 → 스트릭 초기화
        currentStreak = 1;
      }
    } else {
      // 첫 완료
      currentStreak = 1;
    }

    // 오늘 날짜를 완료 목록에 추가 (중복 방지)
    if (!alreadyCompletedToday) {
      completedDates.add(todayString);
      await prefs.setStringList(_completedDatesKey, completedDates);
      await prefs.setString(_lastCompletedDateKey, today.toIso8601String());
      await prefs.setInt(_currentStreakKey, currentStreak);

      print('스트릭 업데이트됨: $currentStreak일');
    }
  }

  // 현재 연도의 완료된 날짜들을 맵으로 반환
  Future<Map<int, bool>> getCompletedDaysMapForCurrentYear(int daysInYear) async {
    final prefs = await SharedPreferences.getInstance();
    final completedDates = prefs.getStringList(_completedDatesKey) ?? [];

    final now = DateTime.now();
    final currentYear = now.year;
    final startOfYear = DateTime(currentYear, 1, 1);

    Map<int, bool> completedMap = {};

    // 올해의 모든 날짜를 확인
    for (int i = 0; i < daysInYear; i++) {
      final date = startOfYear.add(Duration(days: i));
      final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
      completedMap[i] = completedDates.contains(dateString);
    }

    return completedMap;
  }

  // 지난 N일 동안의 완료된 날짜들을 맵으로 반환 (기존 함수)
  Future<Map<int, bool>> getCompletedDaysMap(int numberOfDays) async {
    final prefs = await SharedPreferences.getInstance();
    final completedDates = prefs.getStringList(_completedDatesKey) ?? [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Map<int, bool> completedMap = {};

    for (int i = 0; i < numberOfDays; i++) {
      final date = today.subtract(Duration(days: numberOfDays - 1 - i));
      final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
      completedMap[i] = completedDates.contains(dateString);
    }

    return completedMap;
  }

  // 스트릭 초기화 (테스트용)
  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_lastCompletedDateKey);
    await prefs.remove(_completedDatesKey);
  }
}