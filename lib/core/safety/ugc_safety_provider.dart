import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UgcSafetyNotifier extends StateNotifier<Set<String>> {
  UgcSafetyNotifier() : super({}) {
    _loadBlockedUsers();
  }

  static const _prefKey = 'blocked_users_list';

  Future<void> _loadBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      state = list.toSet();
    } catch (_) {}
  }

  Future<void> blockUser(String identifier) async {
    if (identifier.trim().isEmpty) return;
    final updated = Set<String>.from(state)..add(identifier.trim().toLowerCase());
    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, updated.toList());
    } catch (_) {}
  }

  Future<void> unblockUser(String identifier) async {
    final updated = Set<String>.from(state)..remove(identifier.trim().toLowerCase());
    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, updated.toList());
    } catch (_) {}
  }

  bool isBlocked(String? identifier) {
    if (identifier == null || identifier.trim().isEmpty) return false;
    return state.contains(identifier.trim().toLowerCase());
  }

  Future<bool> reportContent({
    required String contentType,
    required String contentId,
    required String contentTitle,
    required String reportedUser,
    required String reason,
    String? description,
    String? reporterEmail,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'contentType': contentType,
        'contentId': contentId,
        'contentTitle': contentTitle,
        'reportedUser': reportedUser,
        'reason': reason,
        'description': description ?? '',
        'reporterEmail': reporterEmail ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

final ugcSafetyProvider = StateNotifierProvider<UgcSafetyNotifier, Set<String>>((ref) {
  return UgcSafetyNotifier();
});
