import '../../../core/safety/ugc_safety_provider.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/districts.dart';
import '../domain/business_model.dart';

final businessCategoryFilterProvider = StateProvider<String>((ref) => 'Hepsi');
final businessSearchQueryProvider = StateProvider<String>((ref) => '');


final businessesListProvider = StreamProvider<List<BusinessModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('businesses')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => BusinessModel.fromJson(doc.data())).toList();
  });
});

final filteredBusinessesProvider = Provider<AsyncValue<List<BusinessModel>>>((ref) {
  final asyncList = ref.watch(businessesListProvider);
  final district = ref.watch(selectedDistrictProvider);
  final category = ref.watch(businessCategoryFilterProvider);
  final query = ref.watch(businessSearchQueryProvider).toLowerCase();
  final blockedUsers = ref.watch(ugcSafetyProvider);

  return asyncList.whenData((list) {
    final filtered = list.where((b) {
      final isApproved = b.status == 'approved';
      final matchesDistrict = district == 'Diyarbakır' || b.district == district;
      final matchesCategory = category == 'Hepsi' || b.category == category;
      final matchesQuery = b.name.toLowerCase().contains(query) ||
          b.description.toLowerCase().contains(query) ||
          b.address.toLowerCase().contains(query);
      final isBlocked = (b.ownerEmail != null && blockedUsers.contains(b.ownerEmail!.toLowerCase()));
      return isApproved && !isBlocked && matchesDistrict && matchesCategory && matchesQuery;
    }).toList();
    filtered.sort((a, b) => b.id.compareTo(a.id));
    return filtered;
  });
});
