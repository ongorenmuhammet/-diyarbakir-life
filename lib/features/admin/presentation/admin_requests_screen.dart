import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_image.dart';
import '../../classifieds/domain/ad_model.dart';
import '../../classifieds/presentation/ad_provider.dart';
import '../../businesses/domain/business_model.dart';
import '../../businesses/presentation/business_provider.dart';
import '../../jobs/domain/job_model.dart';
import '../../jobs/presentation/job_provider.dart';
import '../../halisaha/domain/hali_saha_model.dart';
import '../../halisaha/presentation/hali_saha_provider.dart';

class AdminRequestsScreen extends ConsumerWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İstekler & İlan Onayları'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.sell_outlined), text: 'İlanlar'),
              Tab(icon: Icon(Icons.work_outline), text: 'İş İlanları'),
              Tab(icon: Icon(Icons.storefront_outlined), text: 'İşletmeler'),
              Tab(icon: Icon(Icons.sports_soccer), text: 'Halı Saha'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingAdsTab(),
            _PendingJobsTab(),
            _PendingBusinessesTab(),
            _PendingHaliSahaTab(),
          ],
        ),
      ),
    );
  }
}

// 1. Pending Ads Tab
class _PendingAdsTab extends ConsumerWidget {
  const _PendingAdsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(adsListProvider);

    return adsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (allAds) {
        final pendingAds = allAds.where((ad) => ad.status != 'approved').toList();

        if (pendingAds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('Onay bekleyen satılık/kiralık ilan bulunmuyor.', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingAds.length,
          itemBuilder: (context, index) {
            final ad = pendingAds[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Onay Bekliyor', style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text('${ad.district} • ${ad.date}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${ad.price} TL • ${ad.ownerName} (${ad.ownerEmail ?? "E-posta yok"})', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(ad.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('ads').doc(ad.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan reddedildi ve silindi.')));
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reddet & Sil', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('ads').doc(ad.id).update({'status': 'approved'});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan onaylandı ve yayına alındı!'), backgroundColor: Colors.green));
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Onayla & Yayınla'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 2. Pending Jobs Tab
class _PendingJobsTab extends ConsumerWidget {
  const _PendingJobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsListProvider);

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (allJobs) {
        final pendingJobs = allJobs.where((job) => job.status != 'approved').toList();

        if (pendingJobs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('Onay bekleyen iş ilanı bulunmuyor.', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingJobs.length,
          itemBuilder: (context, index) {
            final job = pendingJobs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Onay Bekliyor', style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text('${job.district} • ${job.date}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(job.companyName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('İletişim: ${job.contactEmail} (${job.ownerEmail ?? "E-posta yok"})', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(job.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('jobs').doc(job.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İş ilanı reddedildi ve silindi.')));
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reddet & Sil', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('jobs').doc(job.id).update({'status': 'approved'});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İş ilanı onaylandı ve yayına alındı!'), backgroundColor: Colors.green));
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Onayla & Yayınla'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 3. Pending Businesses Tab
class _PendingBusinessesTab extends ConsumerWidget {
  const _PendingBusinessesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bizAsync = ref.watch(businessesListProvider);

    return bizAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (allBiz) {
        final pendingBiz = allBiz.where((b) => b.status != 'approved').toList();

        if (pendingBiz.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('Onay bekleyen işletme kaydı bulunmuyor.', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingBiz.length,
          itemBuilder: (context, index) {
            final biz = pendingBiz[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Onay Bekliyor', style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text('${biz.district} • ${biz.category}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(biz.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(biz.address, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('Telefon: ${biz.phone} (${biz.ownerEmail ?? "E-posta yok"})', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(biz.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('businesses').doc(biz.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşletme reddedildi ve silindi.')));
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reddet & Sil', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('businesses').doc(biz.id).update({'status': 'approved'});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşletme onaylandı ve yayına alındı!'), backgroundColor: Colors.green));
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Onayla & Yayınla'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 4. Pending Halı Saha Tab
class _PendingHaliSahaTab extends ConsumerWidget {
  const _PendingHaliSahaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final haliSahaAsync = ref.watch(haliSahaListProvider);

    return haliSahaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (allHs) {
        final pendingHs = allHs.where((item) => item.status != 'approved').toList();

        if (pendingHs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('Onay bekleyen halı saha ilanı bulunmuyor.', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingHs.length,
          itemBuilder: (context, index) {
            final item = pendingHs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Onay Bekliyor', style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text('${item.district} • ${item.createdAt}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Saha: ${item.pitchName} (${item.matchDate} - ${item.matchTime})', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('İlan Sahibi: ${item.ownerName} (${item.userEmail ?? "E-posta yok"})', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('halisaha').doc(item.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halı saha ilanı reddedildi ve silindi.')));
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reddet & Sil', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('halisaha').doc(item.id).update({'status': 'approved'});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halı saha ilanı onaylandı ve yayına alındı!'), backgroundColor: Colors.green));
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Onayla & Yayınla'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
