import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/storage_service.dart';
import '../models/task_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final StorageService _storageService = StorageService();
  
  List<TaskModel> _allTasks = [];
  int _totalXp = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await _storageService.getTasks();
    final xp = await _storageService.getTotalXp();
    final currentStreak = await _storageService.getStreak();
    final bestStreak = await _storageService.getBestStreak();
    final start = await _storageService.getJourneyStart();

    setState(() {
      _allTasks = tasks;
      _totalXp = xp;
      _currentStreak = currentStreak;
      _bestStreak = bestStreak;
      _startDate = start;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalTasks = _allTasks.length;
    int completedTasks = _allTasks.where((t) => t.isDone).length;
    double completionRate = totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total XP', '$_totalXp', AppColors.accent),
                _buildStatCard('🔥 Streak', '$_currentStreak days', AppColors.green),
                _buildStatCard('Done / Total', '$completedTasks / $totalTasks', AppColors.blue),
                _buildStatCard('Best Streak', '$_bestStreak days', Colors.purpleAccent),
              ],
            ),
            const SizedBox(height: 30),

            // Weekly Chart
            const Text('Last 7 Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildWeeklyChart(),
            ),
            const SizedBox(height: 30),

            // Monthly Heatmap
            const Text('Month Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMonthlyHeatmap(),
            const SizedBox(height: 30),

            // Category Breakdown
            const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildCategoryPieChart(),
            ),
            const SizedBox(height: 30),

            if (_startDate != null)
              Center(
                child: Text(
                  'Journey started on ${DateFormat('MMM d, yyyy').format(_startDate!)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final now = DateTime.now();
    List<BarChartGroupData> barGroups = [];
    
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      int completedOnDay = _allTasks.where((t) => t.isDone && t.date.day == day.day && t.date.month == day.month && t.date.year == day.year).length;
      
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: completedOnDay.toDouble(),
              color: AppColors.accent,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _allTasks.isEmpty ? 5 : null,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                DateTime day = now.subtract(Duration(days: 6 - value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('E').format(day), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    Map<String, int> categoryCounts = {};
    for (var task in _allTasks) {
      if (task.isDone) {
        categoryCounts[task.category] = (categoryCounts[task.category] ?? 0) + 1;
      }
    }

    if (categoryCounts.isEmpty) {
      return const Center(child: Text('No completed tasks yet', style: TextStyle(color: AppColors.textSecondary)));
    }

    List<PieChartSectionData> sections = [];
    categoryCounts.forEach((category, count) {
      sections.add(
        PieChartSectionData(
          color: getCategoryColor(category),
          value: count.toDouble(),
          title: '$count',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: sections,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categoryCounts.keys.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, color: getCategoryColor(cat)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(cat, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyHeatmap() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday; // 1 (Mon) to 7 (Sun)

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: daysInMonth + (startWeekday - 1),
        itemBuilder: (context, index) {
          if (index < startWeekday - 1) return const SizedBox();
          
          final dayNum = index - (startWeekday - 1) + 1;
          final dayDate = DateTime(now.year, now.month, dayNum);
          final tasksDone = _allTasks.where((t) => t.isDone && t.date.year == dayDate.year && t.date.month == dayDate.month && t.date.day == dayDate.day).length;

          Color color;
          if (tasksDone == 0) color = AppColors.surface;
          else if (tasksDone < 2) color = AppColors.green.withAlpha(80);
          else if (tasksDone < 4) color = AppColors.green.withAlpha(160);
          else color = AppColors.green;

          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(fontSize: 8, color: tasksDone > 0 ? Colors.white : AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }
}
