import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasksRef => _db
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('tasks');

  Future<String> addTask({
    required String title,
    required String description,
    List<String> tags = const [],
  }) async {
    final docRef = await _tasksRef.add({
      'title': title,
      'description': description,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'tags': tags,
    });
    return docRef.id;
  }

  Stream<List<Task>> streamTasks({bool? completedFilter}) {
    Query<Map<String, dynamic>> query =
        _tasksRef.orderBy('createdAt', descending: true);

    if (completedFilter != null) {
      query = query.where('isCompleted', isEqualTo: completedFilter);
    }

    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  Future<Task?> getTask(String taskId) async {
    final doc = await _tasksRef.doc(taskId).get();
    return doc.exists ? Task.fromFirestore(doc) : null;
  }

  Future<void> toggleTask(String taskId, bool isCompleted) async {
    await _tasksRef.doc(taskId).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    List<String>? tags,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (tags != null) updates['tags'] = tags;
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _tasksRef.doc(taskId).update(updates);
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }

  Future<void> completeAllTasks() async {
    final batch = _db.batch();
    final snapshot =
        await _tasksRef.where('isCompleted', isEqualTo: false).get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Stream<List<Task>> streamTasksByTag(String tag) {
    return _tasksRef
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  Future<List<Task>> getTasksPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query =
        _tasksRef.orderBy('createdAt', descending: true).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  // PROFILE PHOTO -- small avatar stored as base64 in users/{uid} (no Storage needed)
  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

  Stream<String?> streamProfilePhoto() => _userRef
      .snapshots()
      .map((doc) => doc.data()?['photoBase64'] as String?);

  Future<void> saveProfilePhoto(String base64Image) =>
      _userRef.set({'photoBase64': base64Image}, SetOptions(merge: true));

  // REPORT -- computed on the client (replaces the Cloud Function)
  Future<Map<String, dynamic>> getWeeklyReport() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final all = await _tasksRef.get();
    final completedThisWeek = all.docs.where((d) {
      final done = d.data()['completedAt'];
      return d.data()['isCompleted'] == true &&
          done is Timestamp &&
          done.toDate().isAfter(weekAgo);
    }).length;
    final total = all.size;
    return {
      'totalTasks': total,
      'completedThisWeek': completedThisWeek,
      'completionRate':
          total > 0 ? (completedThisWeek / total * 100).toStringAsFixed(1) : '0',
    };
  }
}
