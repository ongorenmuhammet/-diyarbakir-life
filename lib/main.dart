import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/notifications/notification_provider.dart';

import 'core/notifications/local_notification_service.dart';
import 'core/utils/seeder.dart';
import 'core/ads/ad_service.dart';

import 'firebase_options.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Global flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint("FlutterError caught: ${details.exception}");
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Arayüz yüklenirken bir hata oluştu: ${details.exception}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ),
      );
    };

    // 1. Firebase Başlatma (Maksimum 2 sn zaman aşımı ile asla takılmaz)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint("Firebase başlatma uyarısı: $e");
      try {
        await Firebase.initializeApp().timeout(const Duration(seconds: 1));
      } catch (e2) {
        debugPrint("Firebase varsayılan başlatma uyarısı: $e2");
      }
    }

    try {
      await initializeDateFormatting('tr_TR', null).timeout(const Duration(seconds: 1));
    } catch (_) {}

    // 2. ARAYÜZÜ DERHAL BAŞLAT (Beyaz ekranı %100 engeller)
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // 3. İzinler ve Veritabanı Doldurucu (Arayüz çizildikten sonra arka planda çalışır)
    _initPostStartupServices();
  }, (error, stack) {
    debugPrint("Global unhandled error: $error\n$stack");
  });
}

void _initPostStartupServices() async {
  try {
    DatabaseSeeder.seedIfEmpty().catchError((e) => debugPrint("Seeder hatası: $e"));
  } catch (e) {
    debugPrint("Seeder çalıştırma hatası: $e");
  }

  try {
    await LocalNotificationService.ensurePermission();
  } catch (e) {
    debugPrint("Bildirim izni hatası: $e");
  }

  try {
    await AdService.instance.initialize();
  } catch (e) {
    debugPrint("AdService başlatma hatası: $e");
  }
}

class BroadcastNotificationListener extends ConsumerStatefulWidget {
  final Widget child;
  const BroadcastNotificationListener({super.key, required this.child});

  @override
  ConsumerState<BroadcastNotificationListener> createState() => _BroadcastNotificationListenerState();
}

class _BroadcastNotificationListenerState extends ConsumerState<BroadcastNotificationListener> {
  StreamSubscription? _sub;
  String? _lastNewsId;
  bool _isFirstSnapshot = true;

  @override
  void initState() {
    super.initState();
    _listenNews();
  }

  void _listenNews() {
    try {
      _sub = FirebaseFirestore.instance
          .collection('news')
          .snapshots()
          .listen((snapshot) {
        try {
          if (snapshot.docs.isEmpty) return;

          final docs = List<QueryDocumentSnapshot>.from(snapshot.docs);
          docs.sort((a, b) => b.id.compareTo(a.id));

          final latestDoc = docs.first;
          final latestId = latestDoc.id;

          if (_isFirstSnapshot) {
            _isFirstSnapshot = false;
            _lastNewsId = latestId;
            return;
          }

          if (_lastNewsId == latestId) {
            return;
          }

          if (_lastNewsId != null && latestId.compareTo(_lastNewsId!) <= 0) {
            _lastNewsId = latestId;
            return;
          }

          _lastNewsId = latestId;

          final data = latestDoc.data() as Map<String, dynamic>;
          final title = data['title'] ?? 'Yeni Haber';
          final summary = data['summary'] ?? '';
          final notifySettings = ref.read(notificationSettingsProvider);

          if (notifySettings.newsNotify) {
            LocalNotificationService.showNewsNotification(
              title: title,
              summary: summary,
            );
          }
        } catch (e) {
          debugPrint('Error handling news snapshot: $e');
        }
      }, onError: (e) {
        debugPrint('Error listening to news collection: $e');
      });
    } catch (e) {
      debugPrint('Firestore news listener init error: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Diyarbakır Yerel Yaşam',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) {
        return BroadcastNotificationListener(
          child: child ?? const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}

