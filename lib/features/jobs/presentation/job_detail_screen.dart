import '../../../core/safety/ugc_safety_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/sub_page_pop_scope.dart';
import '../../../core/constants/districts.dart';
import 'job_provider.dart';
import '../domain/job_model.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _sendEmail(String email) async {
    final Uri url = Uri.parse('mailto:${email.trim()}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showJobForm(BuildContext context, JobModel jobItem) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: jobItem.title);
    final companyController = TextEditingController(text: jobItem.companyName);
    final salaryController = TextEditingController(text: jobItem.salary);
    final descriptionController = TextEditingController(text: jobItem.description);
    final emailController = TextEditingController(text: jobItem.contactEmail);
    final phoneController = TextEditingController(text: jobItem.contactPhone);
    final requirementsController = TextEditingController(text: jobItem.requirements.join(', '));
    String selectedJobType = jobItem.jobType;
    String selectedDistrict = jobItem.district;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İş İlanını Düzenle',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Pozisyon Başlığı',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Başlık boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: companyController,
                    decoration: InputDecoration(
                      labelText: 'Firma Adı',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Firma adı boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedJobType,
                          decoration: InputDecoration(
                            labelText: 'Çalışma Şekli',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Tam Zamanlı', child: Text('Tam Zamanlı')),
                            DropdownMenuItem(value: 'Yarı Zamanlı', child: Text('Yarı Zamanlı')),
                            DropdownMenuItem(value: 'Uzaktan', child: Text('Uzaktan')),
                            DropdownMenuItem(value: 'Staj', child: Text('Staj')),
                          ],
                          onChanged: (val) {
                            if (val != null) selectedJobType = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedDistrict,
                          decoration: InputDecoration(
                            labelText: 'İlçe',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: kDistricts.map((String dist) {
                            return DropdownMenuItem(value: dist, child: Text(dist));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) selectedDistrict = val;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: salaryController,
                    decoration: InputDecoration(
                      labelText: 'Maaş Bilgisi (Opsiyonel)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'İletişim E-postası',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'E-posta boş bırakılamaz' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Telefon No (İsteğe Bağlı)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'İş Açıklaması',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 4,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Açıklama boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: requirementsController,
                    decoration: InputDecoration(
                      labelText: 'Aranan Nitelikler (Virgülle ayırın)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Nitelikler alanı boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final reqs = requirementsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          final updatedJob = JobModel(
                            id: jobItem.id,
                            title: titleController.text.trim(),
                            companyName: companyController.text.trim(),
                            district: selectedDistrict,
                            salary: salaryController.text.trim().isEmpty ? null : salaryController.text.trim(),
                            jobType: selectedJobType,
                            description: descriptionController.text.trim(),
                            requirements: reqs,
                            contactEmail: emailController.text.trim(),
                            contactPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                            date: jobItem.date,
                            ownerEmail: jobItem.ownerEmail,
                            status: jobItem.status,
                          );

                          FirebaseFirestore.instance.collection('jobs').doc(updatedJob.id).set(updatedJob.toJson());
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Güncelle'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İlanı Sil'),
          content: const Text('Bu iş ilanını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('jobs').doc(id).delete();
                Navigator.of(context).pop();
                context.pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsListProvider);
    final appliedJobs = ref.watch(appliedJobsProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return jobsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Hata: $err'))),
      data: (jobs) {
        final jobIndex = jobs.indexWhere((element) => element.id == widget.jobId);
        if (jobIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('İş Detayı')),
            body: const Center(child: Text('İş ilanı bulunamadı.')),
          );
        }
        final job = jobs[jobIndex];
        final hasApplied = appliedJobs.contains(job.id);

    final canEdit = authState.isAdmin ||
        (authState.isAuthenticated &&
            authState.email != null &&
            (job.ownerEmail == authState.email ||
                job.contactEmail.toLowerCase() == authState.email!.toLowerCase()));

    return SubPagePopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İş Detayı'),
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
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showJobForm(context, job),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, job.id),
            ),
          ] else
            UgcSafetyActionMenu(
              contentType: 'İş İlanı',
              contentId: job.id,
              contentTitle: job.title,
              reportedUserEmail: job.ownerEmail ?? job.contactEmail,
              reportedUserName: job.companyName,
              onUserBlocked: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job.companyName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Icons.location_on_outlined, 'İlçe', job.district),
                    const SizedBox(height: 10),
                    _buildInfoRow(context, Icons.work_outline, 'Çalışma Türü', job.jobType),
                    const SizedBox(height: 10),
                    _buildInfoRow(context, Icons.calendar_today_outlined, 'Yayınlanma', job.date),
                    if (job.salary != null) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow(context, Icons.payments_outlined, 'Maaş', job.salary!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pozisyon Açıklaması',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aranan Nitelikler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...job.requirements.map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        req,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendEmail(job.contactEmail),
                      icon: const Icon(Icons.email_outlined, size: 20),
                      label: const Text('E-posta Gönder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                if (job.contactPhone != null && job.contactPhone!.trim().isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _makeCall(job.contactPhone!),
                        icon: const Icon(Icons.phone, size: 20),
                        label: const Text('Firmayı Ara'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
