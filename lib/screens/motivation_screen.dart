import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/storage_service.dart';
import '../models/task_model.dart';

class MotivationScreen extends StatefulWidget {
  const MotivationScreen({super.key});

  @override
  State<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends State<MotivationScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  List<TaskModel> _allTasks = [];

  final List<String> _quotes = [
    "Consistency is what transforms average into excellence.",
    "The secret of getting ahead is getting started.",
    "Grind in your 20s. Build your empire.",
    "Don't stop when you're tired. Stop when you're done.",
    "Tough times never last, but tough people do.",
    "A year from now, you will wish you had started today.",
    "Success is the sum of small efforts, repeated day in and day out.",
    "Strive for progress, not perfection.",
    "Your future is created by what you do today, not tomorrow.",
    "Focus on the step in front of you, not the whole staircase."
  ];

  final List<String> _affirmations = [
    "I am learning every day.",
    "I will crack my placement.",
    "I am confident in my skills.",
    "Every bug I fix makes me a better developer."
  ];

  String _currentQuote = "Tap 'Spin for Boost' for motivation!";
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _storageService.getTasks();
    setState(() {
      _allTasks = tasks;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinBoost() async {
    await _controller.forward();
    setState(() {
      _currentQuote = _quotes[Random().nextInt(_quotes.length)];
    });
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boost Card
            GestureDetector(
              onTap: _spinBoost,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.catMock],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.accent.withAlpha(100), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.flash_on, size: 40, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        '$_currentQuote',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Spin for Boost 🔄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Placement Tips
            const Text('Quick Tips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTipTile('Practice 2 DSA problems daily.'),
            _buildTipTile('Update your LinkedIn weekly.'),
            _buildTipTile('Participate in at least 1 mock interview a month.'),
            const SizedBox(height: 30),

            // Affirmations
            const Text('Daily Affirmations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _affirmations.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.green.withAlpha(50)),
                    ),
                    child: Center(
                      child: Text(
                        '"${_affirmations[index]}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: AppColors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Roadmap
            const Text('Placement Roadmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRoadmapStep(1, 'Build Basics (DSA, OOP, OS, DBMS)', AppColors.catDsa, ['DSA', 'Core CS']),
            _buildRoadmapStep(2, 'Practice (LeetCode, Projects)', AppColors.catDev, ['Development']),
            _buildRoadmapStep(3, 'Apply & Prepare (Resume, Mocks)', AppColors.catResume, ['Resume', 'Mock Interview']),
            _buildRoadmapStep(4, 'Placement Season', AppColors.catMock, ['Aptitude', 'Other']),
          ],
        ),
      ),
    );
  }

  Widget _buildTipTile(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.catAptitude, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildRoadmapStep(int step, String title, Color color, List<String> categories) {
    final phaseTasks = _allTasks.where((t) => categories.contains(t.category)).toList();
    final completedCount = phaseTasks.where((t) => t.isDone).length;
    final totalCount = phaseTasks.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withAlpha(50), shape: BoxShape.circle),
                child: Center(child: Text('$step', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface,
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount / $totalCount tasks completed',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
