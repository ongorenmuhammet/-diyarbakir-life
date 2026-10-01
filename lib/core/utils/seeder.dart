import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static Future<void> seedIfEmpty() async {
    final firestore = FirebaseFirestore.instance;

    // 1. Seed Admin User if not exists
    final adminDoc = await firestore.collection('users').doc('admin@bismil.com').get();
    if (!adminDoc.exists) {
      await firestore.collection('users').doc('admin@bismil.com').set({
        'name': 'Sistem Yöneticisi',
        'email': 'admin@bismil.com',
        'password': 'admin123',
        'avatarUrl': '',
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Purge any previously-seeded mock/draft documents from Firestore
    final mockAdIds = ['ad-1', 'ad-2', 'ad-3', 'ad-4', 'ad-5', 'ad-6'];
    for (final id in mockAdIds) {
      try {
        await firestore.collection('ads').doc(id).delete();
      } catch (_) {}
    }

    final mockNewsIds = ['news-1', 'news-2', 'news-3', 'news-4'];
    for (final id in mockNewsIds) {
      try {
        await firestore.collection('news').doc(id).delete();
      } catch (_) {}
    }

    final mockBizIds = ['biz-1', 'biz-2', 'biz-3', 'biz-4'];
    for (final id in mockBizIds) {
      try {
        await firestore.collection('businesses').doc(id).delete();
      } catch (_) {}
    }

    final mockHaliSahaIds = ['hs-1', 'hs-2', 'hs-3', 'hs-4'];
    for (final id in mockHaliSahaIds) {
      try {
        await firestore.collection('halisaha').doc(id).delete();
      } catch (_) {}
    }

    final mockJobIds = ['job-1', 'job-2', 'job-3', 'job-4', 'job-5', 'job-6', 'job-7', 'job-8', 'job-9'];
    for (final id in mockJobIds) {
      try {
        await firestore.collection('jobs').doc(id).delete();
      } catch (_) {}
    }
  }
}
