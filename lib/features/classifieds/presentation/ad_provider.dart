import 'package:flutter/foundation.dart';
import '../../../core/safety/ugc_safety_provider.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/districts.dart';
import '../domain/ad_model.dart';

import '../../../core/auth/auth_provider.dart';

final adCategoryFilterProvider = StateProvider<String>((ref) => 'Hepsi');
final adConditionFilterProvider = StateProvider<String>((ref) => 'Tümü');
final adSearchQueryProvider = StateProvider<String>((ref) => '');

final adsListProvider = StreamProvider<List<AdModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('ads')
      .snapshots()
      .map((snapshot) {
    final list = <AdModel>[];
    for (final doc in snapshot.docs) {
      try {
        list.add(AdModel.fromJson(doc.data()));
      } catch (e) {
        debugPrint('Ad parse error (${doc.id}): $e');
      }
    }
    return list;
  });
});

String _cleanTurkish(String text) {
  return text
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('i̇', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .trim();
}

final filteredAdsProvider = Provider<AsyncValue<List<AdModel>>>((ref) {
  final asyncAds = ref.watch(adsListProvider);
  final district = ref.watch(selectedDistrictProvider);
  final category = ref.watch(adCategoryFilterProvider);
  final condition = ref.watch(adConditionFilterProvider);
  final query = ref.watch(adSearchQueryProvider);
  final authState = ref.watch(authProvider);
  final blockedUsers = ref.watch(ugcSafetyProvider);

  return asyncAds.whenData((ads) {
    final cleanQuery = _cleanTurkish(query);
    final filtered = ads.where((ad) {
      final isApproved = ad.status == 'approved' || authState.isAdmin;
      final matchesDistrict = district == 'Diyarbakır' || ad.district == district;
      final matchesCategory = category == 'Hepsi' || ad.category == category;
      final matchesCondition = condition == 'Tümü' || (ad.condition ?? 'İkinci El') == condition;
      final matchesQuery = cleanQuery.isEmpty ||
          _cleanTurkish(ad.title).contains(cleanQuery) ||
          _cleanTurkish(ad.description).contains(cleanQuery) ||
          _cleanTurkish(ad.ownerName).contains(cleanQuery);
      final isBlocked = (ad.ownerEmail != null && blockedUsers.contains(ad.ownerEmail!.toLowerCase())) ||
          blockedUsers.contains(ad.ownerName.toLowerCase());
      return isApproved && !isBlocked && matchesDistrict && matchesCategory && matchesCondition && matchesQuery;
    }).toList();
    filtered.sort((a, b) => b.id.compareTo(a.id));
    return filtered;
  });
});
