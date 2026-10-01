import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'notification_provider.dart';
import 'local_notification_service.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Bildirim Ayarları'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Notification Preference Toggles Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Bildirim Tercihleri',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İstediğiniz kategorilerdeki bildirimleri açıp kapatarak telefonunuza gelecek uyarıları yönetebilirsiniz.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('🕌 Ezan Vakti Bildirimleri'),
                    subtitle: const Text('İmsak, Öğle, İkindi, Akşam ve Yatsı vakitlerinde anlık sesli/titreşimli uyarı.'),
                    value: settings.prayerNotify,
                    onChanged: (val) => notifier.togglePrayer(val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('🌤️ Sabah Hava Durumu'),
                    subtitle: const Text('Her sabah 08:00\'de günlük hava durumu özeti.'),
                    value: settings.weatherNotify,
                    onChanged: (val) => notifier.toggleWeather(val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('📈 Günün Piyasaları'),
                    subtitle: const Text('Her öğlen 12:00\'de güncel Altın, Dolar ve Euro kurları.'),
                    value: settings.currencyNotify,
                    onChanged: (val) => notifier.toggleCurrency(val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('🗞️ Günün Öne Çıkan Haberleri'),
                    subtitle: const Text('Her akşam 20:00\'de kentteki önemli gelişmeler.'),
                    value: settings.newsNotify,
                    onChanged: (val) => notifier.toggleNews(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 2. Notification Testing Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Bildirim Sistemi Testi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cihazınızda bildirimlerin doğru çalıştığından emin olmak için aşağıdaki test butonlarını kullanabilirsiniz.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: const Text('Anlık Test Bildirimi Gönder'),
                    subtitle: const Text('Hemen bir test bildirimi fırlatır.'),
                    trailing: const Icon(Icons.send_rounded),
                    onTap: () async {
                      await LocalNotificationService.showTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test bildirimi gönderildi!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orangeAccent,
                      child: Icon(Icons.timer_outlined, color: Colors.white),
                    ),
                    title: const Text('5 Saniye Sonra Test Bildirimi'),
                    subtitle: const Text('Zamanlanmış bildirim motorunu test eder.'),
                    trailing: const Icon(Icons.alarm_on_rounded),
                    onTap: () async {
                      await LocalNotificationService.scheduleTestInSeconds(5);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('5 saniye sonra bildirim gelecek. (Uygulamadan çıkıp bekleyebilirsiniz)'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
