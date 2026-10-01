import '../../../core/safety/ugc_safety_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/districts.dart';
import '../../../core/widgets/sub_page_pop_scope.dart';
import '../domain/hali_saha_model.dart';
import 'hali_saha_provider.dart';
import 'add_hali_saha_ad_screen.dart';

class HaliSahaScreen extends ConsumerWidget {
  const HaliSahaScreen({super.key});

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _checkAuthAndCreateAd(BuildContext context, AuthState authState) {
    if (!authState.isAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Giriş Yapmalısınız'),
            ],
          ),
          content: const Text(
            'Halı saha rakip veya oyuncu arama ilanı paylaşmak için oturum açmış olmanız gerekmektedir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/profile');
              },
              icon: const Icon(Icons.login),
              label: const Text('Giriş Yap / Kaydol'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AddHaliSahaAdScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final adsAsync = ref.watch(filteredHaliSahaAdsProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halı Saha - Rakip Bul'),
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
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDistrict,
                icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                dropdownColor: theme.colorScheme.surface,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    ref.read(selectedDistrictProvider.notifier).setDistrict(newValue);
                  }
                },
                items: kDistricts.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _checkAuthAndCreateAd(context, authState),
        icon: const Icon(Icons.sports_soccer),
        label: const Text('Rakip / Oyuncu İlanı Ver'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Info Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) {
                ref.read(haliSahaSearchQueryProvider.notifier).state = val;
              },
              decoration: InputDecoration(
                hintText: 'Halı saha veya rakip ilanı ara...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
              ),
            ),
          ),

          Expanded(
            child: adsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (ads) {
                if (ads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          '$selectedDistrict bölgesinde henüz maç ilanı bulunmuyor.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _checkAuthAndCreateAd(context, authState),
                          icon: const Icon(Icons.add),
                          label: const Text('İlk İlanı Sen Ver'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final item = ads[index];
                    return _buildAdCard(context, ref, item, authState);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, WidgetRef ref, HaliSahaAdModel item, AuthState authState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_soccer, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'İlan Sahibi: ${item.ownerName} • ${item.createdAt}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (authState.isAuthenticated && (authState.isAdmin || authState.email == item.userEmail))
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      FirebaseFirestore.instance.collection('halisaha').doc(item.id).delete();
                    },
                  )
                else
                  UgcSafetyActionMenu(
                    contentType: 'Halı Saha İlanı',
                    contentId: item.id,
                    contentTitle: item.title,
                    reportedUserEmail: item.userEmail ?? '',
                    reportedUserName: item.ownerName,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Match details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailInfo(
                    context,
                    icon: Icons.stadium,
                    title: 'Halı Saha',
                    value: item.pitchName,
                  ),
                ),
                Expanded(
                  child: _buildDetailInfo(
                    context,
                    icon: Icons.calendar_month,
                    title: 'Tarih & Saat',
                    value: '${item.matchDate}\n${item.matchTime}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailInfo(
                    context,
                    icon: Icons.group,
                    title: 'Aranan',
                    value: item.missingCount,
                    valueColor: Colors.orange.shade700,
                  ),
                ),
                Expanded(
                  child: _buildDetailInfo(
                    context,
                    icon: Icons.payments,
                    title: 'Kişi Başı Ücret',
                    value: item.pricePerPerson == 0 ? 'Ücretsiz / Bedava' : '${item.pricePerPerson.toStringAsFixed(0)} TL',
                    valueColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Call Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(item.contactPhone),
                icon: const Icon(Icons.phone),
                label: Text('İletişime Geç (${item.contactPhone})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfo(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
