import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'task_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TaskListScreen(
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Profile',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }
}
