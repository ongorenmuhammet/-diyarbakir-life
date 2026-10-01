import '../../../core/safety/ugc_safety_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/districts.dart';
import '../domain/job_model.dart';

final jobsSearchQueryProvider = StateProvider<String>((ref) => '');

final jobsListProvider = StreamProvider<List<JobModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => JobModel.fromJson(doc.data())).toList();
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

final filteredJobsProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final asyncJobs = ref.watch(jobsListProvider);
  final district = ref.watch(selectedDistrictProvider);
  final query = ref.watch(jobsSearchQueryProvider);
  final blockedUsers = ref.watch(ugcSafetyProvider);

  return asyncJobs.whenData((jobs) {
    final cleanQuery = _cleanTurkish(query);
    final filtered = jobs.where((job) {
      final isApproved = job.status == 'approved';
      final matchesDistrict = district == 'Diyarbakır' || job.district == district;
      final matchesQuery = cleanQuery.isEmpty ||
          _cleanTurkish(job.title).contains(cleanQuery) ||
          _cleanTurkish(job.companyName).contains(cleanQuery) ||
          _cleanTurkish(job.description).contains(cleanQuery);
      final isBlocked = (job.ownerEmail != null && blockedUsers.contains(job.ownerEmail!.toLowerCase())) ||
          blockedUsers.contains(job.contactEmail.toLowerCase()) ||
          blockedUsers.contains(job.companyName.toLowerCase());
      return isApproved && !isBlocked && matchesDistrict && matchesQuery;
    }).toList();
    filtered.sort((a, b) => b.id.compareTo(a.id));
    return filtered;
  });
});

class AppliedJobsNotifier extends StateNotifier<Set<String>> {
  AppliedJobsNotifier() : super({});

  void applyToJob(String jobId) {
    state = {...state, jobId};
  }

  bool hasApplied(String jobId) {
    return state.contains(jobId);
  }
}

final appliedJobsProvider = StateNotifierProvider<AppliedJobsNotifier, Set<String>>((ref) {
  return AppliedJobsNotifier();
});
