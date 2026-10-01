import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/districts.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../domain/prayer_time_model.dart';

final prayerTimesProvider = FutureProvider<PrayerTimeModel>((ref) async {
  final district = ref.watch(selectedDistrictProvider);
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.collection('prayer_times').doc(district);

  final now = DateTime.now();
  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // 1. Try reading from Firestore cache for today
  try {
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['date'] == todayStr) {
        final prayerModel = PrayerTimeModel.fromJson(data);
        // Schedule notifications for prayer times
        LocalNotificationService.schedulePrayerTimes(prayerModel);
        return prayerModel;
      }
    }
  } catch (_) {}

  // 2. Fetch from AlAdhan API if not in Firestore or date changed
  try {
    final url = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
      'city': district,
      'country': 'Turkey',
      'method': '13',
    });
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final model = PrayerTimeModel.fromAladhanJson(jsonResponse, district);

      // Save to Firestore
      try {
        final map = model.toJson();
        map['date'] = todayStr;
        await docRef.set(map);
      } catch (_) {}

      // Schedule local notifications for exact prayer times
      LocalNotificationService.schedulePrayerTimes(model);

      return model;
    } else {
      throw Exception('API Hatası: Ezan vakitleri alınamadı.');
    }
  } catch (e) {
    throw Exception('Ezan vakitleri yüklenemedi. Lütfen internetinizi kontrol edin.');
  }
});

final currentTimeProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});
