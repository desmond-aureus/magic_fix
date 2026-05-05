class TaskModel {
  final String id;
  final String link;
  final String createdBy;
  final int createdAt;
  final String status;
  final String? completedBy;
  final int? completedAt;

  const TaskModel({
    required this.id,
    required this.link,
    required this.createdBy,
    required this.createdAt,
    this.status = 'pending',
    this.completedBy,
    this.completedAt,
  });

  bool get isPending => status == 'pending';
  bool get isDone => status == 'done';

  factory TaskModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return TaskModel(
      id: id,
      link: (map['link'] ?? '') as String,
      createdBy: (map['createdBy'] ?? 'Unknown') as String,
      createdAt: (map['createdAt'] ?? 0) as int,
      status: (map['status'] ?? 'pending') as String,
      completedBy: map['completedBy'] as String?,
      completedAt: map['completedAt'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'link': link,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'status': status,
      if (completedBy != null) 'completedBy': completedBy,
      if (completedAt != null) 'completedAt': completedAt,
    };
  }
}
