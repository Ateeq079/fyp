import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/stats_service.dart';
import 'shared_ui.dart';

class StudySummaryHeader extends StatefulWidget {
  const StudySummaryHeader({super.key});

  @override
  State<StudySummaryHeader> createState() => _StudySummaryHeaderState();
}

class _StudySummaryHeaderState extends State<StudySummaryHeader> {
  final _statsService = StatsService();
  UserStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final stats = await _statsService.getUserStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: LinearProgressIndicator(),
      );
    }

    if (_stats == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '${_stats!.studyStreakDays}d',
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _StatItem(
                icon: Icons.psychology_rounded,
                label: 'Due Today',
                value: '${_stats!.flashcardsDue}',
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _StatItem(
                icon: Icons.emoji_events_rounded,
                label: 'Mastered',
                value: '${_stats!.masteredWords}',
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // --- Daily Goal Card ---
          SoftCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Goal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_stats!.totalVocabulary} / 10 words',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_stats!.totalVocabulary / 10).clamp(0.0, 1.0),
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.secondary,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
