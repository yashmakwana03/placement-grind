import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/storage_service.dart';
import '../models/task_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final StorageService _storageService = StorageService();
  List<TaskModel> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _storageService.getTasks();
    tasks.sort((a, b) => b.date.compareTo(a.date)); // descending date
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _toggleTaskDone(TaskModel task) async {
    final updated = TaskModel(
      id: task.id,
      title: task.title,
      category: task.category,
      isDone: !task.isDone,
      date: task.date,
      xpReward: task.xpReward,
    );
    await _storageService.updateTask(updated);

    if (updated.isDone) {
      await _storageService.addXp(updated.xpReward);
      await _storageService.updateStreakOnTaskCompletion();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+${updated.xpReward} XP Earned! 🎉', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // If unchecking, subtract XP
      await _storageService.addXp(-updated.xpReward);
    }
    _loadTasks();
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => const AddTaskSheet(),
    ).then((_) => _loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final today = DateTime.now();
    final todayTasks = _tasks.where((t) => t.date.day == today.day && t.date.month == today.month && t.date.year == today.year).toList();
    final upcomingTasks = _tasks.where((t) => t.date.isAfter(today) && (t.date.day != today.day || t.date.month != today.month || t.date.year != today.year)).toList();
    final pastTasks = _tasks.where((t) => t.date.isBefore(today) && (t.date.day != today.day || t.date.month != today.month || t.date.year != today.year)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  const Text('No Tasks Yet!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tap + to start your grind', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (todayTasks.isNotEmpty) ...[
                  const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  const SizedBox(height: 10),
                  ...todayTasks.map(_buildTaskCard),
                  const SizedBox(height: 20),
                ],
                if (upcomingTasks.isNotEmpty) ...[
                  const Text('Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...upcomingTasks.map(_buildTaskCard),
                  const SizedBox(height: 20),
                ],
                if (pastTasks.isNotEmpty) ...[
                  const Text('Past', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  ...pastTasks.map(_buildTaskCard),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) async {
                await _storageService.deleteTask(task.id);
                _loadTasks();
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: GestureDetector(
              onTap: () => _toggleTaskDone(task),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isDone ? AppColors.green : Colors.transparent,
                  border: Border.all(color: task.isDone ? AppColors.green : AppColors.textSecondary, width: 2),
                ),
                width: 28,
                height: 28,
                child: task.isDone ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                color: task.isDone ? AppColors.textSecondary : Colors.white,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getCategoryColor(task.category).withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.category,
                      style: TextStyle(fontSize: 10, color: getCategoryColor(task.category), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d').format(task.date),
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('+${task.xpReward} XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
            ),
          ),
        ),
      ),
    );
  }
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  final List<String> _categories = ['DSA', 'Development', 'Aptitude', 'Resume', 'Core CS', 'Mock Interview', 'Other'];
  String _selectedCategory = 'DSA';
  int _selectedXp = 50;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Task', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'What are you working on?',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 20),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: getCategoryColor(cat).withAlpha(50),
                backgroundColor: AppColors.card,
                onSelected: (val) => setState(() => _selectedCategory = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('XP Reward', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [25, 50, 100].map((xp) {
              final isSelected = _selectedXp == xp;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedXp = xp),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('$xp XP', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                if (_titleController.text.trim().isEmpty) return;
                final task = TaskModel(
                  id: const Uuid().v4(),
                  title: _titleController.text.trim(),
                  category: _selectedCategory,
                  date: _selectedDate,
                  xpReward: _selectedXp,
                );
                await StorageService().addTask(task);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Add Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
