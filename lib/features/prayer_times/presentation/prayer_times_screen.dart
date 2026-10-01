import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/prayer_time_model.dart';
import 'prayer_times_provider.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

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
    return '$hours:$minutes:$seconds';
  }

  String _getVakitKalanText(String name) {
    switch (name) {
      case 'İmsak': return "İmsak Vaktine Kalan";
      case 'Güneş': return "Güneş Doğuşuna Kalan";
      case 'Öğle': return "Öğle Vaktine Kalan";
      case 'İkindi': return "İkindi Vaktine Kalan";
      case 'Akşam': return "Akşam Vaktine Kalan";
      case 'Yatsı': return "Yatsı Vaktine Kalan";
      default: return "$name Vaktine Kalan";
    }
  }

  LinearGradient _getPrayerGradient(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F172A), // Slate 900
          Color(0xFF1E1E38), // Midnight Navy
          Color(0xFF030712), // Deep Space black
        ],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE0F2FE), // Sky 100
          Color(0xFFF3E8FF), // Purple 100
          Color(0xFFFDF2F8), // Pink 50
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesAsync = ref.watch(prayerTimesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradient = _getPrayerGradient(isDark);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7);
    final cardBorderColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: timesAsync.whenOrNull(data: (t) => Text('${t.district} Ezan Vakitleri', style: const TextStyle(fontWeight: FontWeight.bold))) ??
            const Text('Ezan Vakitleri', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: timesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Ezan vakitleri alınamadı.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(prayerTimesProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Deneyin'),
                  ),
                ],
              ),
            ),
            data: (times) {
              final now = ref.watch(currentTimeProvider).value ?? DateTime.now();
              final nextVakit = _getNextVakit(times, now);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Circular Countdown Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: cardBorderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getVakitKalanText(nextVakit.name),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatDuration(nextVakit.remaining),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_active_outlined, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                              const SizedBox(width: 8),
                              Text(
                                'Sıradaki Vakit: ${nextVakit.name} (${nextVakit.time})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Vakit list title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bugünkü Ezan Vakitleri',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vakit Rows
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: cardBorderColor),
                      ),
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            _buildPrayerRow(context, 'İmsak', times.imsak, Icons.nightlight_round, nextVakit.name == 'İmsak'),
                            const Divider(height: 1),
                            _buildPrayerRow(context, 'Güneş', times.gunes, Icons.wb_twilight, nextVakit.name == 'Güneş'),
                            const Divider(height: 1),
                            _buildPrayerRow(context, 'Öğle', times.ogle, Icons.wb_sunny_outlined, nextVakit.name == 'Öğle'),
                            const Divider(height: 1),
                            _buildPrayerRow(context, 'İkindi', times.ikindi, Icons.wb_sunny, nextVakit.name == 'İkindi'),
                            const Divider(height: 1),
                            _buildPrayerRow(context, 'Akşam', times.aksam, Icons.brightness_3, nextVakit.name == 'Akşam'),
                            const Divider(height: 1),
                            _buildPrayerRow(context, 'Yatsı', times.yatsi, Icons.nightlight, nextVakit.name == 'Yatsı'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Vakit bilgileri Diyanet İşleri Başkanlığı uyumludur.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerRow(BuildContext context, String name, String time, IconData icon, bool isNext) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rowBg = isNext
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : Colors.transparent;

    final color = isNext 
        ? theme.colorScheme.primary 
        : theme.colorScheme.onSurface.withValues(alpha: 0.8);
    final fw = isNext ? FontWeight.w800 : FontWeight.bold;

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNext ? theme.colorScheme.primary.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Text(name, style: TextStyle(fontWeight: fw, fontSize: 16, color: color)),
          const Spacer(),
          Text(
            time, 
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: fw, 
              color: color,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
