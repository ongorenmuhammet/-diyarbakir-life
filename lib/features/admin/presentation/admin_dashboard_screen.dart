import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/auth/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated || !authState.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yetkisiz Erişim')),
        body: const Center(
          child: Text('Bu sayfayı görüntüleme yetkiniz yok.'),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim Paneli'),
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
          // Analytics Section
          Text(
            'Günlük Giriş İstatistikleri',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _DailyLoginChart(),
          const SizedBox(height: 24),

          Text(
            'İçerik Yönetimi',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAdminCard(
            context,
            title: 'Haber Yönetimi',
            subtitle: 'Haber ekle, düzenle veya sil.',
            icon: Icons.article_outlined,
            color: Colors.blue,
            onTap: () => context.push('/news'),
          ),
          _buildAdminCard(
            context,
            title: 'İşletme Yönetimi',
            subtitle: 'İşletmeleri ve menülerini yönet.',
            icon: Icons.storefront_outlined,
            color: Colors.orange,
            onTap: () => context.push('/businesses'),
          ),
          _buildAdminCard(
            context,
            title: 'İlan Yönetimi',
            subtitle: 'Satılık/Kiralık ilanları düzenle.',
            icon: Icons.shopping_bag_outlined,
            color: Colors.green,
            onTap: () => context.push('/classifieds'),
          ),
          const SizedBox(height: 32),
          Text(
            'Sistem',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAdminCard(
            context,
            title: 'Çıkış Yap',
            subtitle: 'Admin hesabından çıkış yap.',
            icon: Icons.logout,
            color: Colors.red,
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyLoginChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get last 7 days date keys
    final now = DateTime.now();
    final dateKeys = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_outlined, color: Colors.deepPurple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kullanıcı Giriş & Üye İstatistikleri',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                final totalUsers = usersSnapshot.hasData ? usersSnapshot.data!.docs.length : 0;
                
                return StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: FirebaseFirestore.instance
                      .collection('daily_logins')
                      .where(FieldPath.documentId, whereIn: dateKeys)
                      .snapshots()
                      .map((s) => s.docs),
                  builder: (context, loginsSnapshot) {
                    if (loginsSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final docs = loginsSnapshot.data ?? [];
                    final Map<String, int> loginMap = {};
                    int totalWeek = 0;
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final count = (data['count'] as num?)?.toInt() ?? 0;
                      loginMap[doc.id] = count;
                      totalWeek += count;
                    }

                    final maxCount = loginMap.values.fold<int>(1, (a, b) => a > b ? a : b);

                    return Column(
                      children: [
                        // Summary row with 3 chips
                        Row(
                          children: [
                            _buildSummaryChip(
                              context,
                              icon: Icons.people_outline,
                              label: 'Toplam Üye',
                              value: '$totalUsers',
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            _buildSummaryChip(
                              context,
                              icon: Icons.today,
                              label: 'Bugün Giriş',
                              value: '${loginMap[dateKeys.last] ?? 0}',
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            _buildSummaryChip(
                              context,
                              icon: Icons.date_range,
                              label: 'Haftalık',
                              value: '$totalWeek',
                              color: Colors.deepPurple.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Bar chart
                        SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: dateKeys.map((dateKey) {
                              final count = loginMap[dateKey] ?? 0;
                              final heightRatio = maxCount > 0 ? count / maxCount : 0.0;
                              final dayLabel = dateKey.substring(8); // DD

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: count > 0 ? Colors.deepPurple : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 400),
                                        height: (heightRatio * 70).clamp(4.0, 70.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          gradient: LinearGradient(
                                            colors: count > 0
                                                ? [Colors.deepPurple.shade300, Colors.deepPurple.shade600]
                                                : [Colors.grey.shade300, Colors.grey.shade400],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        dayLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
