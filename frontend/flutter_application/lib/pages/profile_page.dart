import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../services/stats_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _statsService = StatsService();
  UserStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _statsService.getUserStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ateeq', // Placeholder for user name
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Study Streak: ${_stats?.studyStreakDays ?? 1} days 🔥',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                StatCard(
                  title: 'Documents',
                  value: '${_stats?.totalDocuments ?? 0}',
                  icon: Icons.description,
                ),
                const SizedBox(height: 12),
                StatCard(
                  title: 'Vocabulary Saved',
                  value: '${_stats?.totalVocabulary ?? 0}',
                  icon: Icons.menu_book,
                ),
                const SizedBox(height: 12),
                StatCard(
                  title: 'Quizzes Taken',
                  value: '${_stats?.totalQuizzes ?? 0}',
                  icon: Icons.quiz,
                ),
                const SizedBox(height: 12),
                StatCard(
                  title: 'Words Mastered',
                  value: '${_stats?.masteredWords ?? 0}',
                  icon: Icons.emoji_events,
                ),
                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showComingSoon(context, 'Edit Profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Privacy & Security'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showComingSoon(context, 'Privacy & Security');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Appearance'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showComingSoon(context, 'Appearance settings');
                  },
                ),
              ],
            ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
