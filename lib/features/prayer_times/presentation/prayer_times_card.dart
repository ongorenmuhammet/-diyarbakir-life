import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/prayer_time_model.dart';
import 'prayer_times_provider.dart';

class PrayerTimesCard extends ConsumerWidget {
  const PrayerTimesCard({super.key});

  ({String name, String time, Duration remaining}) _getNextVakit(PrayerTimeModel times, DateTime now) {
    DateTime parseTime(String timeStr) {
      final parts = timeStr.split(':');
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    }

    final vakitler = [
      {'name': 'İmsak', 'time': times.imsak, 'dt': parseTime(times.imsak)},
      {'name': 'Güneş', 'time': times.gunes, 'dt': parseTime(times.gunes)},
      {'name': 'Öğle', 'time': times.ogle, 'dt': parseTime(times.ogle)},
      {'name': 'İkindi', 'time': times.ikindi, 'dt': parseTime(times.ikindi)},
      {'name': 'Akşam', 'time': times.aksam, 'dt': parseTime(times.aksam)},
      {'name': 'Yatsı', 'time': times.yatsi, 'dt': parseTime(times.yatsi)},
    ];

    for (final v in vakitler) {
      final dt = v['dt'] as DateTime;
      if (dt.isAfter(now)) {
        return (
          name: v['name'] as String,
          time: v['time'] as String,
          remaining: dt.difference(now),
        );
      }
    }

    // Eğer tüm vakitler geçtiyse (yatsıdan sonra), ertesi günün imsağıdır
    final nextImsak = parseTime(times.imsak).add(const Duration(days: 1));
    return (
      name: 'İmsak',
      time: times.imsak,
      remaining: nextImsak.difference(now),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesAsync = ref.watch(prayerTimesProvider);
    final now = ref.watch(currentTimeProvider).value ?? DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [theme.colorScheme.surface, theme.colorScheme.surface.withValues(alpha: 0.85)]
            : [theme.colorScheme.primary.withValues(alpha: 0.08), theme.colorScheme.primary.withValues(alpha: 0.02)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? Colors.grey.shade800 : theme.colorScheme.primary.withValues(alpha: 0.12),
        width: 1,
      ),
    );

    return timesAsync.when(
      data: (times) {
        final nextVakit = _getNextVakit(times, now);
        return InkWell(
          onTap: () => context.push('/prayer-times'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration,
            child: Row(
              children: [
                Icon(
                  Icons.mosque,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ezan Vakitleri',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${nextVakit.name} • ${nextVakit.time}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${_formatDuration(nextVakit.remaining)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration,
        height: 70,
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vakitler yüklenemedi',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
