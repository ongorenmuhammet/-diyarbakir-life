import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/news_model.dart';
import '../../../core/constants/districts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final newsCategoryFilterProvider = StateProvider<String>((ref) => 'Hepsi');
final newsSearchQueryProvider = StateProvider<String>((ref) => '');

final newsListProvider = StreamProvider<List<NewsModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('news')
      .snapshots()
      .map((snapshot) {
    final list = <NewsModel>[];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        list.add(NewsModel.fromJson(data, doc.id));
      } catch (e) {
        debugPrint('Haber okuma hatası (${doc.id}): $e');
      }
    }
    return list;
  }).handleError((error) {
    debugPrint('newsListProvider stream error: $error');
    return <NewsModel>[];
  });
});

final filteredNewsProvider = Provider<AsyncValue<List<NewsModel>>>((ref) {
  final newsAsync = ref.watch(newsListProvider);
  final selectedCategory = ref.watch(newsCategoryFilterProvider);
  final searchQuery = ref.watch(newsSearchQueryProvider).toLowerCase();
  final currentDistrict = ref.watch(selectedDistrictProvider);

  // If user selected Bismil, filter Bismil news. Otherwise show Diyarbakır news.
  final targetNewsDistrict = currentDistrict == 'Bismil' ? 'Bismil' : 'Diyarbakır';

  return newsAsync.when(
    data: (news) {
      final filtered = news.where((item) {
        final matchesDistrict = item.district == targetNewsDistrict || item.district == 'Diyarbakır';
        final matchesCategory = selectedCategory == 'Hepsi' || item.category == selectedCategory;
        final matchesSearch = searchQuery.isEmpty ||
            item.title.toLowerCase().contains(searchQuery) ||
            item.summary.toLowerCase().contains(searchQuery) ||
            item.content.toLowerCase().contains(searchQuery);
        return matchesDistrict && matchesCategory && matchesSearch;
      }).toList();
      filtered.sort((a, b) => b.id.compareTo(a.id));
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) {
      debugPrint('filteredNewsProvider error fallback: $err');
      return const AsyncValue.data(<NewsModel>[]);
    },
  );
});