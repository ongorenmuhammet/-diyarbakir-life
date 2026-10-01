import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/districts.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../domain/weather_model.dart';

// ---------------------------------------------------------------------------
// Verified GPS coordinates for all districts (all respond with Europe/Istanbul)
// ---------------------------------------------------------------------------
const _coordinates = {
  'Kayapınar': {'lat': '37.9358', 'lon': '40.1656'},
  'Sur':        {'lat': '37.9136', 'lon': '40.2361'},
  'Yenişehir':  {'lat': '37.9272', 'lon': '40.2198'},
  'Bağlar':     {'lat': '37.9015', 'lon': '40.1800'},
  'Diyarbakır': {'lat': '37.9158', 'lon': '40.2189'},
  'Bismil':     {'lat': '37.8482', 'lon': '40.6681'},
  'Ergani':     {'lat': '37.9814', 'lon': '39.7619'},
  'Silvan':     {'lat': '38.1408', 'lon': '41.0069'},
  'Çınar':      {'lat': '37.7175', 'lon': '40.4144'},
};

// ---------------------------------------------------------------------------
// WMO code → Turkish description and icon
// ---------------------------------------------------------------------------
String _getCondition(int code) {
  if (code == 0)                        return 'Açık, Güneşli';
  if (code == 1)                        return 'Az Bulutlu';
  if (code == 2)                        return 'Parçalı Bulutlu';
  if (code == 3)                        return 'Kapalı';
  if (code == 45 || code == 48)         return 'Sisli';
  if (code >= 51 && code <= 55)         return 'Çiseleme';
  if (code >= 61 && code <= 65)         return 'Yağmurlu';
  if (code >= 71 && code <= 75)         return 'Karlı';
  if (code >= 80 && code <= 82)         return 'Sağanak Yağış';
  if (code >= 95 && code <= 99)         return 'Gök Gürültülü Fırtına';
  return 'Parçalı Bulutlu';
}

String _getIcon(int code) {
  if (code == 0 || code == 1) return 'sunny';
  if (code >= 51 && code <= 82) return 'cloudy';
  if (code >= 95) return 'windy';
  return 'cloudy';
}

// ---------------------------------------------------------------------------
// Single district fetch with Firestore 30-minute Smart Caching
// ---------------------------------------------------------------------------
Future<WeatherModel> _fetchWeatherData(String district, bool isSelected) async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.collection('weather').doc(district);

  // 1. Try reading from Firestore cache (valid for 30 minutes)
  try {
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data.containsKey('updatedAt')) {
        final Timestamp updatedAt = data['updatedAt'] as Timestamp;
        final difference = DateTime.now().difference(updatedAt.toDate());
        if (difference.inMinutes < 30) {
          final weatherModel = WeatherModel.fromJson(data);
          if (isSelected) {
            //LocalNotificationService.scheduleWeatherNotification(
              //districtName: district,
              //tempStr: '${weatherModel.temp}°C',
              //conditionStr: weatherModel.condition,
            //);
          }
          return weatherModel;
        }
      }
    }
  } catch (_) {}

  // 2. Fetch fresh weather data from Open-Meteo API
  final coord = _coordinates[district] ?? _coordinates['Diyarbakır']!;

  final url = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude':  coord['lat']!,
    'longitude': coord['lon']!,
    'current':   'temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,weather_code',
    'daily':     'weather_code,temperature_2m_max,temperature_2m_min',
    'timezone':  'Europe/Istanbul',
  });

  final response = await http.get(url).timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }

  final data    = json.decode(response.body) as Map<String, dynamic>;
  final current = data['current']            as Map<String, dynamic>;
  final daily   = data['daily']              as Map<String, dynamic>;

  final temp      = (current['temperature_2m']       as num).round();
  final feelsLike = (current['apparent_temperature'] as num).round();
  final humidity  = (current['relative_humidity_2m'] as num).round();
  final wind      = (current['wind_speed_10m']       as num).toDouble();
  final code      = (current['weather_code']         as num).toInt();

  final dailyCodes = daily['weather_code']       as List<dynamic>;
  final dailyMax   = daily['temperature_2m_max'] as List<dynamic>;

  const weekdays  = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  final todayIdx  = DateTime.now().weekday - 1;

  final forecast = <DailyForecast>[];
  for (int i = 0; i < 5 && i < dailyCodes.length; i++) {
    forecast.add(DailyForecast(
      dayName:   i == 0 ? 'Bugün' : weekdays[(todayIdx + i) % 7],
      temp:      (dailyMax[i] as num).round(),
      condition: _getCondition((dailyCodes[i] as num).toInt()),
      icon:      _getIcon((dailyCodes[i] as num).toInt()),
    ));
  }

  final weather = WeatherModel(
    district:  district,
    temp:      temp,
    feelsLike: feelsLike,
    humidity:  humidity,
    windSpeed: wind,
    condition: _getCondition(code),
    icon:      _getIcon(code),
    forecast:  forecast,
  );

  if (isSelected) {
    //LocalNotificationService.scheduleWeatherNotification(
      //districtName: district,
      //tempStr: '${weather.temp}°C',
      //conditionStr: weather.condition,
    //);
  }

  // 3. Save fresh data to Firestore for all users to share
  try {
    final weatherMap = weather.toJson();
    weatherMap['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(weatherMap);
  } catch (_) {}

  return weather;
}

// ---------------------------------------------------------------------------
// Shared cache: fetches districts, refreshes every 30 minutes.
// ---------------------------------------------------------------------------
class WeatherCacheNotifier
    extends StateNotifier<Map<String, AsyncValue<WeatherModel>>> {
  final Ref _ref;
  Timer? _timer;

  WeatherCacheNotifier(this._ref) : super({}) {
    _fetchAll();
    // Refresh every 30 minutes automatically
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => _fetchAll());
  }

  /// Fetches all districts in parallel.
  Future<void> _fetchAll() async {
    final selectedDistrict = _ref.read(selectedDistrictProvider);
    await Future.wait(kDistricts.map((district) async {
      if (!state.containsKey(district)) {
        state = {...state, district: const AsyncValue.loading()};
      }
      try {
        final weather = await _fetchWeatherData(district, district == selectedDistrict);
        state = {...state, district: AsyncValue.data(weather)};
      } catch (e, st) {
        if (state[district] is! AsyncData) {
          state = {...state, district: AsyncValue.error(e, st)};
        }
      }
    }));
  }

  void refresh() => _fetchAll();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final weatherCacheProvider = StateNotifierProvider<WeatherCacheNotifier,
    Map<String, AsyncValue<WeatherModel>>>((ref) {
  return WeatherCacheNotifier(ref);
});

final weatherProvider = Provider<AsyncValue<WeatherModel>>((ref) {
  final district = ref.watch(selectedDistrictProvider);
  final cache    = ref.watch(weatherCacheProvider);
  return cache[district] ?? const AsyncValue.loading();
});
