import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/storage_service.dart';
import '../models/task_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storageService = StorageService();
  
  List<TaskModel> _allTasks = [];
  List<TaskModel> _todayTasks = [];
  int _level = 1;
  int _totalXp = 0;
  int _streak = 0;
  int _totalTasks = 0;

  final List<String> _quotes = [
    "Consistency is what transforms average into excellence.",
    "The secret of getting ahead is getting started.",
    "Grind now, shine later. Your future self will thank you.",
    "Small steps every day lead to big results.",
    "Don't wait for opportunity. Create it.",
    "Focus on your goals, not your obstacles.",
    "Success doesn't come to you, you go to it.",
  ];

  String _getDailyQuote() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await _storageService.getTasks();
    final now = DateTime.now();
    
    final int streak = await _storageService.getStreak();
    final int xp = await _storageService.getTotalXp();
    final int level = await _storageService.getLevel();

    setState(() {
      _allTasks = tasks;
      _streak = streak;
      _totalXp = xp;
      _level = level;
      _totalTasks = tasks.where((t) => t.isDone).length;
      _todayTasks = tasks.where((t) {
        return t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day;
      }).toList();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    int tasksDoneToday = _todayTasks.where((t) => t.isDone).length;
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          backgroundColor: AppColors.surface,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, Yash',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${_getDailyQuote()}"',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),

                // XP Card
                _buildXpCard(),
                const SizedBox(height: 20),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard('🔥 Streak', '$_streak days'),
                    _buildStatCard('✅ Today', '$tasksDoneToday/${_todayTasks.length}'),
                    _buildStatCard('📅 Total', '$_totalTasks done'),
                  ],
                ),
                const SizedBox(height: 30),

                // Today's Tasks Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Today\'s Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (tasksDoneToday == _todayTasks.length && _todayTasks.isNotEmpty)
                      const Text('🎉 All done today!', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold))
                  ],
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                _buildTasksPreview(),
                const SizedBox(height: 30),

                const Text('Activity (Last 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildActivityHeatmap(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityHeatmap() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = now.subtract(Duration(days: 6 - index));
          final tasksDone = _allTasks.where((t) => t.isDone && t.date.year == day.year && t.date.month == day.month && t.date.day == day.day).length;
          
          Color barColor;
          if (tasksDone == 0) barColor = AppColors.surface;
          else if (tasksDone < 2) barColor = AppColors.green.withAlpha(100);
          else if (tasksDone < 4) barColor = AppColors.green.withAlpha(180);
          else barColor = AppColors.green;

          return Column(
            children: [
              Container(
                height: 40,
                width: 30,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildXpCard() {
    int nextLevelXp = _level * 500;
    int currentLevelXp = _totalXp - ((_level - 1) * 500);
    double progress = currentLevelXp / 500.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $_level', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_totalXp XP', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(5)),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$currentLevelXp / 500 XP to Level ${_level + 1}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksPreview() {
    if (_todayTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('🏖️ No tasks for today!', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return Column(
      children: _todayTasks.take(3).map((task) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              task.isDone ? Icons.check_circle : Icons.circle_outlined,
              color: task.isDone ? AppColors.green : AppColors.textSecondary,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                color: task.isDone ? AppColors.textSecondary : Colors.white,
              ),
            ),
            trailing: Chip(
              label: Text(task.category, style: const TextStyle(fontSize: 10)),
              backgroundColor: getCategoryColor(task.category).withAlpha(50),
              side: BorderSide.none,
            ),
          ),
        );
      }).toList(),
    );
  }
}
