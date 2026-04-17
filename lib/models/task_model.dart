class TaskModel {
  String id;         // UUID
  String title;
  String category;   // DSA, Development, etc.
  bool isDone;
  DateTime date;
  int xpReward;      // 25, 50, or 100

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    this.isDone = false,
    required this.date,
    required this.xpReward,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'isDone': isDone,
      'date': date.toIso8601String(),
      'xpReward': xpReward,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      isDone: json['isDone'],
      date: DateTime.parse(json['date']),
      xpReward: json['xpReward'],
    );
  }
}
