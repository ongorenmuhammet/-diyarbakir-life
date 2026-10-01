import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/districts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image.dart';
import '../../weather/presentation/weather_card.dart';
import '../../prayer_times/presentation/prayer_times_card.dart';
import '../../finance/presentation/finance_card.dart';
import '../../news/domain/news_model.dart';
import '../../news/presentation/news_provider.dart';
import '../../pharmacies/domain/pharmacy_model.dart';
import '../../pharmacies/presentation/pharmacy_provider.dart';
import '../../businesses/domain/business_model.dart';
import '../../businesses/presentation/business_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final newsAsync = ref.watch(newsListProvider);
    final businessesAsync = ref.watch(filteredBusinessesProvider);
    final pharmaciesAsync = ref.watch(filteredPharmaciesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
          title: Row(
            children: [
              Icon(Icons.location_on, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedDistrict,
                  icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
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
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(pharmaciesListProvider.notifier).fetchPharmacies();
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Expanded(child: WeatherCard()),
                      SizedBox(width: 12),
                      Expanded(child: PrayerTimesCard()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Dollar, Euro, Gold & Silver rates
                const FinanceCard(),
                const SizedBox(height: 28),
                
                // Duty Pharmacies Section
                _buildSectionHeader(
                  context,
                  title: 'Nöbetçi Eczaneler',
                  subtitle: selectedDistrict == 'Diyarbakır' ? 'Tüm ilçelerde bugün' : '$selectedDistrict bölgesinde bugün',
                  onSeeAll: () => context.push('/pharmacies'),
                ),
                const SizedBox(height: 12),
                pharmaciesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _buildEmptyWidget(context, 'Eczaneler yüklenemedi.'),
                  data: (pharmacies) {
                    final topPharmacies = pharmacies.take(2).toList();
                    if (topPharmacies.isEmpty) {
                      return _buildEmptyWidget(context, 'Bugün nöbetçi eczane bulunmuyor.');
                    }
                    return Column(
                      children: topPharmacies.map((ph) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildPharmacyPreviewCard(context, ph),
                      )).toList(),
                    );
                  }
                ),
                const SizedBox(height: 24),
                
                // Featured Businesses Section (BEFORE NEWS)
                _buildSectionHeader(
                  context,
                  title: 'Öne Çıkan İşletmeler',
                  subtitle: selectedDistrict == 'Diyarbakır' ? 'Şehrin seçkin mekanları' : '$selectedDistrict mekanları',
                  onSeeAll: () => context.go('/businesses'),
                ),
                const SizedBox(height: 12),
                businessesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _buildEmptyWidget(context, 'İşletmeler yüklenemedi.'),
                  data: (businesses) {
                    final featuredBiz = businesses.where((b) => b.isFeatured).toList();
                    if (featuredBiz.isEmpty) {
                      return _buildEmptyWidget(context, 'Öne çıkan işletme bulunmuyor.');
                    }
                    return _buildBusinessesHorizontalList(context, featuredBiz);
                  }
                ),
                const SizedBox(height: 28),

                // News Section
                _buildSectionHeader(
                  context,
                  title: 'Öne Çıkan Haberler',
                  subtitle: 'Kentteki son gelişmeler',
                  onSeeAll: () => context.go('/news'),
                ),
                const SizedBox(height: 12),
                newsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _buildNewsHorizontalList(context, defaultDiyarbakirNews),
                  data: (news) {
                    final featuredNews = news.where((n) => n.isFeatured).toList();
                    final displayList = featuredNews.isNotEmpty ? featuredNews : (news.isNotEmpty ? news : defaultDiyarbakirNews);
                    return _buildNewsHorizontalList(context, displayList);
                  }
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required String subtitle, required VoidCallback onSeeAll}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: [
              Text(
                'Tümü',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyWidget(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildPharmacyPreviewCard(BuildContext context, PharmacyModel ph) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          child: const Icon(Icons.local_pharmacy, color: Colors.red),
        ),
        title: Text(
          ph.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${ph.district} • ${ph.address}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/pharmacies'),
      ),
    );
  }

  Widget _buildNewsHorizontalList(BuildContext context, List<NewsModel> news) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: news.length,
        itemBuilder: (context, index) {
          final item = news[index];
          return Container(
            width: 240,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/news/${item.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppImage(
                      path: item.coverImageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.source} • ${item.date}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessesHorizontalList(BuildContext context, List<BusinessModel> businesses) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: businesses.length,
        itemBuilder: (context, index) {
          final b = businesses[index];
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/businesses/${b.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        AppImage(
                          path: b.coverImageUrl,
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                b.category,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                ' • ${b.district}',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
