import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/sub_page_pop_scope.dart';
import '../../classifieds/presentation/ad_provider.dart';
import '../../businesses/presentation/business_provider.dart';
import '../../jobs/presentation/job_provider.dart';
import '../../halisaha/presentation/hali_saha_provider.dart';

class UserListingsScreen extends ConsumerWidget {
  const UserListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('İlanlarım & Gönderilerim'),
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
          bottom: const TabBar(
            isScrollable: false,
            labelPadding: EdgeInsets.symmetric(horizontal: 2.0),
            labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 11),
            tabs: [
              Tab(icon: Icon(Icons.sell_outlined, size: 20), text: 'İlanlarım'),
              Tab(icon: Icon(Icons.work_outline, size: 20), text: 'İş İlanları'),
              Tab(icon: Icon(Icons.storefront_outlined, size: 20), text: 'İşletmeler'),
              Tab(icon: Icon(Icons.sports_soccer, size: 20), text: 'Halı Saha'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyAdsTab(),
            _MyJobsTab(),
            _MyBusinessesTab(),
            _MyHaliSahaTab(),
          ],
        ),
      ),
    );
  }
}

// 1. My Ads Tab
class _MyAdsTab extends ConsumerWidget {
  const _MyAdsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(adsListProvider);
    final auth = ref.watch(authProvider);

    return adsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (allAds) {
        final myAds = allAds.where((ad) => ad.ownerEmail?.toLowerCase() == auth.email?.toLowerCase()).toList();

        if (myAds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sell_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Henüz bir satılık/kiralık ilanınız bulunmuyor.', style: TextStyle(fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myAds.length,
          itemBuilder: (context, index) {
            final ad = myAds[index];
            final isApproved = ad.status == 'approved';

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
                            color: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isApproved ? '🟢 Yayında' : '🟠 Onay Bekliyor',
                            style: TextStyle(
                              color: isApproved ? Colors.green.shade900 : Colors.orange.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text('${ad.district} • ${ad.date}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${ad.price} TL • ${ad.category}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(ad.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('ads').doc(ad.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlanınız silindi.')));
                          },
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

// 2. My Jobs Tab
class _MyJobsTab extends ConsumerWidget {
  const _MyJobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsListProvider);
    final auth = ref.watch(authProvider);

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (allJobs) {
        final myJobs = allJobs.where((job) =>
          job.ownerEmail?.toLowerCase() == auth.email?.toLowerCase() ||
          job.contactEmail.toLowerCase() == auth.email?.toLowerCase()).toList();

        if (myJobs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Henüz bir iş ilanınız bulunmuyor.', style: TextStyle(fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myJobs.length,
          itemBuilder: (context, index) {
            final job = myJobs[index];
            final isApproved = job.status == 'approved';

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
                            color: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isApproved ? '🟢 Yayında' : '🟠 Onay Bekliyor',
                            style: TextStyle(
                              color: isApproved ? Colors.green.shade900 : Colors.orange.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text('${job.district} • ${job.date}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(job.companyName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('jobs').doc(job.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İş ilanınız silindi.')));
                          },
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

// 3. My Businesses Tab
class _MyBusinessesTab extends ConsumerWidget {
  const _MyBusinessesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bizAsync = ref.watch(businessesListProvider);
    final auth = ref.watch(authProvider);

    return bizAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (allBiz) {
        final myBiz = allBiz.where((b) => b.ownerEmail?.toLowerCase() == auth.email?.toLowerCase()).toList();

        if (myBiz.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Henüz kayıtlı bir işletmeniz bulunmuyor.', style: TextStyle(fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myBiz.length,
          itemBuilder: (context, index) {
            final biz = myBiz[index];
            final isApproved = biz.status == 'approved';

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
                            color: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isApproved ? '🟢 Yayında' : '🟠 Onay Bekliyor',
                            style: TextStyle(
                              color: isApproved ? Colors.green.shade900 : Colors.orange.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text('${biz.district} • ${biz.category}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(biz.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(biz.address, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('businesses').doc(biz.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşletme kaydınız silindi.')));
                          },
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

// 4. My Halı Saha Tab
class _MyHaliSahaTab extends ConsumerWidget {
  const _MyHaliSahaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hsAsync = ref.watch(haliSahaListProvider);
    final auth = ref.watch(authProvider);

    return hsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (allHs) {
        final myHs = allHs.where((item) => item.userEmail?.toLowerCase() == auth.email?.toLowerCase()).toList();

        if (myHs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Henüz bir halı saha ilanınız bulunmuyor.', style: TextStyle(fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myHs.length,
          itemBuilder: (context, index) {
            final item = myHs[index];
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
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🟢 Yayında',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text('${item.district} • ${item.createdAt}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Saha: ${item.pitchName} (${item.matchDate} - ${item.matchTime})', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('halisaha').doc(item.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halı saha ilanınız silindi.')));
                          },
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
