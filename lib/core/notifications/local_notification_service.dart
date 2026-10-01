import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/prayer_times/domain/prayer_time_model.dart';
import '../../features/finance/presentation/finance_detail_sheet.dart';
import '../../features/finance/presentation/finance_provider.dart';
import '../routing/app_router.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      try {
        final dynamic timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        final String tzName = timeZoneInfo is String ? timeZoneInfo : (timeZoneInfo?.identifier?.toString() ?? 'Europe/Istanbul');
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
          final payload = response.payload;
          if (payload == 'finance') {
            final context = rootNavigatorKey.currentContext;
            if (context != null) {
              appRouter.go('/home');
              Future.microtask(() {
                final container = ProviderScope.containerOf(context);
                final financeAsync = container.read(financeProvider);
                financeAsync.whenData((finance) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => FinanceDetailSheet(finance: finance),
                  );
                });
              });
            }
          }
        },
      );

      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService.initialize error: $e');
    }
  }

  static Future<bool> ensurePermission() async {
    try {
      await initialize();

      // 1. Android Bildirim Kanalı ve İzni
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'bismil_general_v11',
            'Genel Bildirimler',
            description: 'Diyarbakır Yerel Yaşam Bildirimleri',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
        await android.requestNotificationsPermission();
      }

      // 2. iOS Yerel Bildirim İzni
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // 3. Firebase Cloud Messaging (Push) İzni ve Ön Plan Sunumu
      try {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint('FCM İzin durumu: ${settings.authorizationStatus}');

        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('FCM izin alma uyarısı: $e');
      }
    } catch (e) {
      debugPrint('ensurePermission error: $e');
    }
    return true;
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    String channelId = 'bismil_general_v11',
    String channelName = 'Genel Bildirimler',
  }) async {
    if (!_initialized) await initialize();

    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('exactAllowWhileIdle failed ($e), falling back to inexactAllowWhileIdle');
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
      debugPrint('Bildirim $id zamanlandı: $hour:$minute');
    } catch (e) {
      debugPrint('scheduleDaily error: $e');
    }
  }

  static Future<void> scheduleTestInSeconds(int seconds) async {
    if (!_initialized) await initialize();

    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'bismil_general_v11',
          'Genel Bildirimler',
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          icon: 'ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        await _plugin.zonedSchedule(
          9998,
          '⏱️ Zamanlanmış Test Bildirimi',
          'Harika! Zamanlanmış bildirim sistemi sorunsuz çalışıyor.',
          scheduledDate,
          details,
          payload: 'finance',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          9998,
          '⏱️ Zamanlanmış Test Bildirimi',
          'Harika! Zamanlanmış bildirim sistemi sorunsuz çalışıyor.',
          scheduledDate,
          details,
          payload: 'finance',
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('scheduleTestInSeconds error: $e');
    }
  }

  static Future<void> cancel(int id) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(id);
  }

  static Future<String?> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'bismil_general_v11',
            'Genel Bildirimler',
            importance: Importance.max,
            priority: Priority.max,
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: true,
            icon: 'ic_notification',
            ticker: title,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      return null;
    } catch (e) {
      debugPrint('Notification show error: $e');
      return e.toString();
    }
  }

  // ─── 5 VAKİT EZAN BİLDİRİMLERİ ───
  static Future<void> schedulePrayerTimes(PrayerTimeModel model) async {
    final times = [
      {'id': 3001, 'remindId': 3101, 'name': 'İmsak Vakti', 'time': model.imsak, 'body': 'İmsak vakti girdi. Hayırlı sabahlar.'},
      {'id': 3002, 'remindId': 3102, 'name': 'Öğle Ezanı', 'time': model.ogle, 'body': 'Öğle ezanı okunmaktadır. Hayırlı vakitler.'},
      {'id': 3003, 'remindId': 3103, 'name': 'İkindi Ezanı', 'time': model.ikindi, 'body': 'İkindi ezanı okunmaktadır. Hayırlı vakitler.'},
      {'id': 3004, 'remindId': 3104, 'name': 'Akşam Ezanı', 'time': model.aksam, 'body': 'Akşam ezanı okunmaktadır. Hayırlı vakitler.'},
      {'id': 3005, 'remindId': 3105, 'name': 'Yatsı Ezanı', 'time': model.yatsi, 'body': 'Yatsı ezanı okunmaktadır. Hayırlı geceler.'},
    ];

    for (var item in times) {
      final String timeStr = item['time'] as String;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1].split(' ')[0]) ?? 0;

        // 1. Tam Ezan Vakti Bildirimi
        await _scheduleDaily(
          id: item['id'] as int,
          title: '🕌 ${item['name']} (${item['time']})',
          body: item['body'] as String,
          hour: hour,
          minute: minute,
        );

        // 2. Ezan Vaktinden 45 Dakika Önceki Hatırlatıcı Bildirim
        final totalMinutes = hour * 60 + minute - 45;
        final remindTotalMinutes = totalMinutes < 0 ? totalMinutes + 1440 : totalMinutes;
        final remindHour = (remindTotalMinutes ~/ 60) % 24;
        final remindMin = remindTotalMinutes % 60;

        await _scheduleDaily(
          id: item['remindId'] as int,
          title: '⏳ ${item['name']} Vaktine 45 Dk Kaldı (${item['time']})',
          body: '${item['name']} vaktine 45 dakika kaldı. Hazırlığınızı yapabilirsiniz.',
          hour: remindHour,
          minute: remindMin,
        );
      }
    }
  }

  static Future<void> cancelPrayerNotifications() async {
    for (int id in [3001, 3002, 3003, 3004, 3005, 3101, 3102, 3103, 3104, 3105]) {
      await cancel(id);
    }
  }

  // ─── KATEGORİ TEST BİLDİRİMLERİ ───
  static Future<String?> showPrayerTestNotification() => show(
        id: 9001,
        title: '🕌 Ezan Vakti Test Uyarısı',
        body: 'Akşam Ezanı okunmaktadır. (Test bildirimi)',
      );

  static Future<String?> showWeatherTestNotification() => show(
        id: 9002,
        title: '🌤️ Hava Durumu Test Uyarısı',
        body: 'Diyarbakır bugün 32°C Açık ve Güneşli! (Test bildirimi)',
      );

  static Future<String?> showCurrencyTestNotification() => show(
        id: 9003,
        title: '📈 Serbest Piyasa & Döviz Kurları',
        body: 'Canlı Altın, Dolar ve Euro kurlarını incelemek ister misiniz? Dokunarak canlı kurları anında açabilirsiniz.',
        payload: 'finance',
      );

  static Future<String?> showNewsTestNotification() => show(
        id: 9004,
        title: '🗞️ Son Dakika Haber Testi',
        body: 'Diyarbakır ve Bismil ilçesinden yeni haber var! (Test bildirimi)',
      );

  static Future<void> scheduleWeatherNotification({
    String? districtName,
    String? tempStr,
    String? conditionStr,
  }) => _scheduleDaily(
        id: 2001,
        title: '🌤️ Hava Durumu: ${districtName ?? "Diyarbakır"}',
        body: tempStr != null && conditionStr != null
            ? '${districtName ?? "Diyarbakır"} ilçesinde bugün hava $tempStr, $conditionStr. Detaylar için dokunun.'
            : 'Diyarbakır ve ilçelerinde hava durumu güncellendi. İncelemek için dokunun.',
        hour: 8,
        minute: 0,
      );

  static Future<void> scheduleCurrencyNotification() async {
    // 1. Sabah 10:00 (Piyasa Açılışı)
    await _scheduleDaily(
      id: 2002,
      title: '📈 Serbest Piyasa & Döviz Kurları',
      body: 'Günün piyasa açılışında Dolar, Euro ve Altın kurlarını incelemek ister misiniz? Canlı kurlar için dokunun.',
      hour: 10,
      minute: 0,
      payload: 'finance',
    );

    // 2. Akşam 17:30 (Piyasa Kapanışı)
    await _scheduleDaily(
      id: 2006,
      title: '📈 Günün Piyasa Kapanış Kurları',
      body: 'Piyasa kapanışında Dolar, Euro ve Altın kurlarını kontrol etmek ister misiniz? Detaylar için dokunun.',
      hour: 17,
      minute: 30,
      payload: 'finance',
    );
  }

  static Future<void> cancelCurrencyNotifications() async {
    await cancel(2002);
    await cancel(2006);
  }

  static Future<void> scheduleNewsNotification() => _scheduleDaily(
        id: 2004,
        title: '🗞️ Günün Öne Çıkan Haberleri',
        body: 'Kentteki son dakika gelişmeleri incelemek için dokunun.',
        hour: 20,
        minute: 0,
      );

  static Future<String?> showNewsNotification({String? title, String? summary}) =>
      show(
        id: 2005,
        title: '🚨 SON DAKİKA: ${title ?? "Diyarbakır'dan yeni haber"}',
        body: summary ?? 'Diyarbakır ve ilçelerinden son dakika haberi. Detaylar için tıklayın.',
      );

  static Future<String?> showTestNotification() => show(
        id: 9999,
        title: '🔔 Bildirim Testi Başarılı!',
        body: 'Diyarbakır Yerel Yaşam bildirim sisteminiz sorunsuz çalışmaktadır.',
      );
}
