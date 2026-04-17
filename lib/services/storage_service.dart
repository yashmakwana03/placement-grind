import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _totalXpKey = 'totalXp';
  static const String _streakKey = 'streak';
  static const String _bestStreakKey = 'bestStreak';
  static const String _lastActiveDateKey = 'lastActiveDate';
  static const String _startDateKey = 'startDate';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // --- Tasks ---
  Future<List<TaskModel>> getTasks() async {
    final prefs = await _getPrefs();
    final tasksStr = prefs.getString(_tasksKey);
    if (tasksStr == null) return [];
    
    List<dynamic> jsonList = jsonDecode(tasksStr);
    return jsonList.map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    final prefs = await _getPrefs();
    final jsonList = tasks.map((e) => e.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(jsonList));
  }

  Future<void> addTask(TaskModel task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await saveTasks(tasks);
    await _checkJourneyStart();
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String id) async {
    final tasks = await getTasks();
    tasks.removeWhere((t) => t.id == id);
    await saveTasks(tasks);
  }

  // --- Date Formatter ---
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // --- XP & Level ---
  Future<int> getTotalXp() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_totalXpKey) ?? 0;
  }

  Future<void> addXp(int amount) async {
    final prefs = await _getPrefs();
    int current = prefs.getInt(_totalXpKey) ?? 0;
    await prefs.setInt(_totalXpKey, current + amount);
  }

  Future<int> getLevel() async {
    int totalXp = await getTotalXp();
    return (totalXp ~/ 500) + 1;
  }

  // --- Streak ---
  Future<int> getStreak() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_streakKey) ?? 0;
  }

  Future<int> getBestStreak() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_bestStreakKey) ?? 0;
  }

  Future<void> updateStreakOnTaskCompletion() async {
    final prefs = await _getPrefs();
    String today = _formatDate(DateTime.now());
    String? lastActive = prefs.getString(_lastActiveDateKey);

    if (lastActive == today) {
      // Already incremented streak today
      return;
    }

    int currentStreak = prefs.getInt(_streakKey) ?? 0;

    if (lastActive == null) {
      currentStreak = 1;
    } else {
      DateTime lastDate = DateTime.parse(lastActive);
      DateTime now = DateTime.now();
      Duration diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day));

      if (diff.inDays == 1) {
        currentStreak += 1;
      } else if (diff.inDays > 1) {
        currentStreak = 1; // reset
      }
    }

    await prefs.setInt(_streakKey, currentStreak);
    await prefs.setString(_lastActiveDateKey, today);

    int bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    if (currentStreak > bestStreak) {
      await prefs.setInt(_bestStreakKey, currentStreak);
    }
  }

  // --- Journey Start Date ---
  Future<void> _checkJourneyStart() async {
    final prefs = await _getPrefs();
    if (!prefs.containsKey(_startDateKey)) {
      await prefs.setString(_startDateKey, DateTime.now().toIso8601String());
    }
  }

  Future<DateTime?> getJourneyStart() async {
    final prefs = await _getPrefs();
    final str = prefs.getString(_startDateKey);
    return str != null ? DateTime.parse(str) : null;
  }
}
