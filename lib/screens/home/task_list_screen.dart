import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/analytics_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  final List<Widget> actions;

  const TaskListScreen({super.key, this.actions = const []});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _firestoreService = FirestoreService();
  final _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView('task_list');
    NotificationService().initialize().catchError((Object e) {
      debugPrint('Notification setup failed: $e');
    });
  }

  Future<void> _showAddTaskDialog() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final tags = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: tags,
              decoration:
                  const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );

    if (ok == true && title.text.trim().isNotEmpty) {
      await _firestoreService.addTask(
        title: title.text.trim(),
        description: description.text.trim(),
        tags: tags.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      );
      _analytics.logTaskCreated('basic');
    }
    title.dispose();
    description.dispose();
    tags.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Complete all',
            onPressed: _firestoreService.completeAllTasks,
          ),
          ...widget.actions,
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firestoreService.streamTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks yet. Add one!'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onToggle: (v) {
                  _firestoreService.toggleTask(task.id, v);
                  if (v) {
                    _analytics.logTaskCompleted(
                        DateTime.now().difference(task.createdAt).inDays);
                  }
                },
                onDelete: () => _firestoreService.deleteTask(task.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
