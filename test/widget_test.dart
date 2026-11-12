import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app_interfaces/models/task.dart';

void main() {
  test('Task.toFirestore keeps its fields', () {
    final task = Task(
      id: '1',
      title: 'Test',
      description: 'desc',
      isCompleted: false,
      createdAt: DateTime(2026, 1, 1),
      userId: 'u1',
      tags: const ['a'],
    );
    final map = task.toFirestore();
    expect(map['title'], 'Test');
    expect(map['tags'], ['a']);
    expect(map['isCompleted'], false);
  });

  testWidgets('plain MaterialApp builds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('ok')));
    expect(find.text('ok'), findsOneWidget);
  });
}
