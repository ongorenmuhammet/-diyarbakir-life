import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';

class NotificationSettings {
  final bool weatherNotify; // Sabah 08:00'de hava durumu
  final bool currencyNotify; // Öğlen 12:00'de döviz kurları
  final bool prayerNotify; // Vakitlerden 45 dk önce ezan bildirimi
  final bool newsNotify; // Yeni haber eklendiğinde anında bildirim

  const NotificationSettings({
    this.weatherNotify = true,
    this.currencyNotify = true,
    this.prayerNotify = true,
    this.newsNotify = true,
  });

  NotificationSettings copyWith({
    bool? weatherNotify,
    bool? currencyNotify,
    bool? prayerNotify,
    bool? newsNotify,
  }) {
    return NotificationSettings(
      weatherNotify: weatherNotify ?? this.weatherNotify,
      currencyNotify: currencyNotify ?? this.currencyNotify,
      prayerNotify: prayerNotify ?? this.prayerNotify,
      newsNotify: newsNotify ?? this.newsNotify,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  static const _weatherKey = 'notify_weather_enabled';
  static const _currencyKey = 'notify_currency_enabled';
  static const _prayerKey = 'notify_prayer_enabled';
  static const _newsKey = 'notify_news_enabled';

  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weather = prefs.getBool(_weatherKey) ?? true;
      final currency = prefs.getBool(_currencyKey) ?? true;
      final prayer = prefs.getBool(_prayerKey) ?? true;
      final news = prefs.getBool(_newsKey) ?? true;

      state = NotificationSettings(
        weatherNotify: weather,
        currencyNotify: currency,
        prayerNotify: prayer,
        newsNotify: news,
      );

      // Otomatik Arka Plan Zamanlamaları
      if (weather) {
        await LocalNotificationService.scheduleWeatherNotification();
      }
      if (currency) {
        await LocalNotificationService.scheduleCurrencyNotification();
      }
      if (news) {
        await LocalNotificationService.scheduleNewsNotification();
      }
    } catch (e) {
      debugPrint('NotificationSettingsNotifier _loadSettings error: $e');
    }
  }

  Future<void> toggleWeather(bool value) async {
    state = state.copyWith(weatherNotify: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_weatherKey, value);
      
      // Arka plan zamanlamasını yönet
      if (value) {
        await LocalNotificationService.scheduleWeatherNotification();
      } else {
        await LocalNotificationService.cancel(2001);
      }
    } catch (_) {}
  }

  Future<void> toggleCurrency(bool value) async {
    state = state.copyWith(currencyNotify: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_currencyKey, value);
      
      if (value) {
        await LocalNotificationService.scheduleCurrencyNotification();
      } else {
        await LocalNotificationService.cancelCurrencyNotifications();
      }
    } catch (_) {}
  }

  Future<void> togglePrayer(bool value) async {
    state = state.copyWith(prayerNotify: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prayerKey, value);
      
      if (!value) {
        await LocalNotificationService.cancelPrayerNotifications();
      }
    } catch (_) {}
  }

  Future<void> toggleNews(bool value) async {
    state = state.copyWith(newsNotify: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_newsKey, value);
      
      if (value) {
        await LocalNotificationService.scheduleNewsNotification();
      } else {
        await LocalNotificationService.cancel(2004);
      }
    } catch (_) {}
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});
