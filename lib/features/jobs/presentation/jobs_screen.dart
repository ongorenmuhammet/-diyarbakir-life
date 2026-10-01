import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/districts.dart';
import 'job_provider.dart';
import '../domain/job_model.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  void _showJobForm(BuildContext context, WidgetRef ref, [JobModel? jobItem]) {
    final isEdit = jobItem != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: jobItem?.title);
    final companyController = TextEditingController(text: jobItem?.companyName);
    final salaryController = TextEditingController(text: jobItem?.salary);
    final descriptionController = TextEditingController(text: jobItem?.description);
    final emailController = TextEditingController(text: jobItem?.contactEmail ?? '');
    final phoneController = TextEditingController(text: jobItem?.contactPhone);
    
    // We can join the requirements list with a newline or comma, let's use comma for editing
    final requirementsController = TextEditingController(
      text: jobItem?.requirements.join(', ') ?? '',
    );
    
    String selectedJobType = jobItem?.jobType ?? 'Tam Zamanlı';
    String selectedDistrict = jobItem?.district ?? ref.read(selectedDistrictProvider);

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
                    isEdit ? 'İş İlanını Düzenle' : 'Yeni İş İlanı Ekle',
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
                      hintText: 'Örn: 25.000 TL - 30.000 TL',
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
                          keyboardType: TextInputType.emailAddress,
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
                      hintText: 'Örn: Deneyimli olmak, Ehliyeti olmak',
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

                          final auth = ref.read(authProvider);
                          final isPending = !auth.isAdmin && (!isEdit || jobItem.status == 'pending');
                          final updatedJob = JobModel(
                            id: isEdit ? jobItem.id : 'job-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text.trim(),
                            companyName: companyController.text.trim(),
                            district: selectedDistrict,
                            salary: salaryController.text.trim().isEmpty ? null : salaryController.text.trim(),
                            jobType: selectedJobType,
                            description: descriptionController.text.trim(),
                            requirements: reqs,
                            contactEmail: emailController.text.trim(),
                            contactPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                            date: isEdit ? jobItem.date : 'Bugün',
                            ownerEmail: isEdit ? jobItem.ownerEmail : auth.email,
                            status: isPending ? 'pending' : (isEdit ? jobItem.status : 'approved'),
                          );

                          FirebaseFirestore.instance.collection('jobs').doc(updatedJob.id).set(updatedJob.toJson());
                          Navigator.of(context).pop();
                          if (isPending) {
                            _showApprovalWaitingDialog(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('İş ilanı yayınlandı.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEdit ? 'Güncelle' : 'Kaydet'),
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

  void _showApprovalWaitingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade900, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Onay Bekliyor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'İş ilanınız yöneticimizin onayına sunulmuştur. Yönetici onayladıktan hemen sonra yayında olacaktır.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(filteredJobsProvider);
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final appliedJobs = ref.watch(appliedJobsProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('İş İlanları'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDistrict,
                icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                dropdownColor: theme.colorScheme.surface,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    ref.read(selectedDistrictProvider.notifier).setDistrict(newValue);
                  }
                },
                items: kDistricts.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: authState.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () => _showJobForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('İlan Ekle'),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) => ref.read(jobsSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: '$selectedDistrict iş ilanlarında ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          
          // Jobs Feed
          Expanded(
            child: jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            '$selectedDistrict ilçesinde aktif iş ilanı bulunmamaktadır.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildJobCard(context, job),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => context.push('/jobs/${job.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job.jobType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                job.companyName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.black12),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    job.district,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  if (job.salary != null) ...[
                    const Icon(Icons.payments_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      job.salary!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'Detaylar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 14, color: theme.colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
