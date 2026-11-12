import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/avatar_service.dart';
import '../../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _avatar = AvatarService();
  final _firestore = FirestoreService();
  Map<String, dynamic>? _report;
  bool _busy = false;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _changePhoto() async {
    setState(() => _busy = true);
    try {
      final b64 = await _avatar.pickAvatarBase64();
      if (b64 != null) await _firestore.saveProfilePhoto(b64);
    } catch (e) {
      if (mounted) _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadReport() async {
    setState(() => _busy = true);
    try {
      final report = await _firestore.getWeeklyReport();
      setState(() => _report = report);
    } catch (e) {
      if (mounted) _snack('Report failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _busy ? null : _changePhoto,
              child: StreamBuilder<String?>(
                stream: _firestore.streamProfilePhoto(),
                builder: (context, snapshot) {
                  final b64 = snapshot.data;
                  final fallback = user?.photoURL;
                  final ImageProvider? image = b64 != null
                      ? MemoryImage(base64Decode(b64))
                      : (fallback != null ? NetworkImage(fallback) : null);
                  return CircleAvatar(
                    radius: 48,
                    backgroundImage: image,
                    child: image == null
                        ? const Icon(Icons.add_a_photo, size: 32)
                        : null,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(user?.displayName ?? '',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Center(child: Text(user?.email ?? '')),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _busy ? null : _loadReport,
            icon: const Icon(Icons.bar_chart),
            label: const Text('Weekly report'),
          ),
          if (_report != null)
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total tasks: ${_report!['totalTasks']}'),
                    Text('Completed this week: ${_report!['completedThisWeek']}'),
                    Text('Completion rate: ${_report!['completionRate']}%'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () async {
              final nav = Navigator.of(context);
              await _auth.signOut();
              nav.popUntil((r) => r.isFirst);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
