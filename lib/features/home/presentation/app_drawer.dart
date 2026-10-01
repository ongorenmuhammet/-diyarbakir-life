import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/app_image.dart';
import '../../profile/presentation/edit_profile_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, authState, theme),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.local_pharmacy_outlined,
                  title: 'Nöbetçi Eczaneler',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/pharmacies');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Hava Durumu',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/weather');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.sports_soccer,
                  title: 'Halı Saha (Rakip Bul)',
                  iconColor: Colors.green,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/halisaha');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.contact_support_outlined,
                  title: 'İletişim & Şikayet/Öneri',
                  iconColor: Colors.blue.shade700,
                  onTap: () {
                    Navigator.of(context).pop();
                    _showContactDialog(context);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Gizlilik Politikası',
                  onTap: () async {
                    Navigator.of(context).pop();
                    final url = Uri.parse('https://sites.google.com/view/zkproduction/privacy-policy-diyarbak%C4%B1r-life');
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint('Link acilamadi: $e');
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'Uygulama Hakkında',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0 • Diyarbakır Yerel Yaşam',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthState auth, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: auth.isAuthenticated
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: AppImage(
                        path: auth.avatarUrl!,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                      tooltip: 'Profili Düzenle',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                      },
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  auth.name!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.email!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_activity,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Diyarbakır Yerel Yaşam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Şehrinizin güncel yaşam rehberi',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Diyarbakır Yerel Yaşam'),
        content: const Text(
          'Diyarbakır ili ve ilçelerindeki günlük yaşam rehberinizdir.\n\n'
          'Uygulama üzerinden nöbetçi eczaneleri görebilir, güncel hava durumuna bakabilir, yerel haberleri inceleyebilir, iş ilanlarına başvurabilir veya satış ilanları oluşturabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.headset_mic_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Text('İletişim & Destek'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Şikayet, öneri veya iş birliği talepleriniz için bize ulaşabilirsiniz:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Telefon İletişim Kartı
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: '+905443183777');
                try {
                  await launchUrl(phoneUri);
                } catch (e) {
                  debugPrint('Telefon uygulamasi acilamadi: $e');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.phone, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Telefon İletişim',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          SelectableText(
                            '+90 544 318 37 77',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // E-posta İletişim Kartı
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'ozgorenkasim00@gmail.com',
                  queryParameters: {'subject': 'Şikayet ve Öneri - Yerel Yaşam Uygulaması'},
                );
                try {
                  await launchUrl(emailLaunchUri);
                } catch (_) {}
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.email, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'E-Posta Adresi',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          SelectableText(
                            'ozgorenkasim00@gmail.com',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final Uri phoneUri = Uri(scheme: 'tel', path: '+905443183777');
              try {
                await launchUrl(phoneUri);
              } catch (e) {
                debugPrint('Telefon uygulamasi acilamadi: $e');
              }
            },
            icon: const Icon(Icons.phone_in_talk, size: 16),
            label: const Text('Hemen Ara'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
