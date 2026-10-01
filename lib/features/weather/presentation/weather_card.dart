import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'weather_provider.dart';

class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
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

    return weatherAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        decoration: cardDecoration,
        child: Row(
          children: [
            Icon(Icons.wb_sunny_rounded, size: 32, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hava Durumu', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: cardDecoration,
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 28, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hava durumu alınamadı',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      data: (weather) => InkWell(
        onTap: () => context.push('/weather'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration,
          child: Row(
            children: [
              Icon(
                _getWeatherIcon(weather.icon),
                size: 38,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${weather.district} Hava',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weather.condition,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${weather.temp}°C',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '5 Günlük',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 12, color: theme.colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String iconName) {
    switch (iconName) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'windy':
        return Icons.air_rounded;
      case 'cloudy':
        return Icons.wb_cloudy_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }
}
