import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference _tasksRef(String boardId) =>
      _db.ref('boards/$boardId/tasks');

  Stream<List<TaskModel>> tasksStream(String boardId) {
    return _tasksRef(boardId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <TaskModel>[];
      final map = Map<String, dynamic>.from(data as Map);
      return map.entries.map((e) {
        return TaskModel.fromMap(
          e.key,
          Map<dynamic, dynamic>.from(e.value as Map),
        );
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> addTask({
    required String boardId,
    required String link,
    required String createdBy,
  }) async {
    final ref = _tasksRef(boardId).push();
    await ref.set({
      'link': link,
      'createdBy': createdBy,
      'createdAt': ServerValue.timestamp,
      'status': 'pending',
    });
  }

  Future<void> completeTask({
    required String boardId,
    required String taskId,
    required String completedBy,
  }) async {
    await _tasksRef(boardId).child(taskId).update({
      'status': 'done',
      'completedBy': completedBy,
      'completedAt': ServerValue.timestamp,
    });
  }
}
