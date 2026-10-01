import '../../../core/safety/ugc_safety_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/districts.dart';
import '../domain/hali_saha_model.dart';

final haliSahaSearchQueryProvider = StateProvider<String>((ref) => '');

final haliSahaListProvider = StreamProvider<List<HaliSahaAdModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('halisaha')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => HaliSahaAdModel.fromJson(doc.data())).toList();
  });
});

final filteredHaliSahaAdsProvider = Provider<AsyncValue<List<HaliSahaAdModel>>>((ref) {
  final adsAsync = ref.watch(haliSahaListProvider);
  final district = ref.watch(selectedDistrictProvider);
  final query = ref.watch(haliSahaSearchQueryProvider).toLowerCase();
  final blockedUsers = ref.watch(ugcSafetyProvider);

  return adsAsync.whenData((list) {
    final filtered = list.where((item) {
      final isApproved = true; // Halı saha ilanları onay gerektirmeden yayınlanır
      final matchesDistrict = district == 'Diyarbakır' || item.district == district;
      final matchesQuery = item.title.toLowerCase().contains(query) ||
          item.pitchName.toLowerCase().contains(query) ||
          item.missingCount.toLowerCase().contains(query);
      final isBlocked = (item.userEmail != null && blockedUsers.contains(item.userEmail!.toLowerCase())) ||
          blockedUsers.contains(item.ownerName.toLowerCase());
      return isApproved && !isBlocked && matchesDistrict && matchesQuery;
    }).toList();
    filtered.sort((a, b) => b.id.compareTo(a.id));
    return filtered;
  });
});
