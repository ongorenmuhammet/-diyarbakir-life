import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/districts.dart';
import '../domain/hali_saha_model.dart';
import 'hali_saha_provider.dart';

class AddHaliSahaAdScreen extends ConsumerStatefulWidget {
  const AddHaliSahaAdScreen({super.key});

  @override
  ConsumerState<AddHaliSahaAdScreen> createState() => _AddHaliSahaAdScreenState();
}

class _AddHaliSahaAdScreenState extends ConsumerState<AddHaliSahaAdScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _pitchController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _missingController;
  late TextEditingController _priceController;
  late TextEditingController _phoneController;

  String _selectedDistrict = 'Kayapınar';

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final currentDist = ref.read(selectedDistrictProvider);
    if (currentDist != 'Diyarbakır' && kDistricts.contains(currentDist)) {
      _selectedDistrict = currentDist;
    } else {
      _selectedDistrict = 'Bismil';
    }

    _titleController = TextEditingController();
    _pitchController = TextEditingController();
    _dateController = TextEditingController();
    _timeController = TextEditingController();
    _missingController = TextEditingController();
    _priceController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pitchController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _missingController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final newAd = HaliSahaAdModel(
      id: 'hs-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      district: _selectedDistrict,
      pitchName: _pitchController.text.trim(),
      matchDate: _dateController.text.trim(),
      matchTime: _timeController.text.trim(),
      missingCount: _missingController.text.trim(),
      pricePerPerson: double.tryParse(_priceController.text.trim()) ?? 0.0,
      contactPhone: _phoneController.text.trim(),
      ownerName: auth.name ?? 'İlan Sahibi',
      userEmail: auth.email,
      createdAt: 'Şimdi',
      status: 'approved',
    );

    // İlanı Firestore'a ekle
    FirebaseFirestore.instance.collection('halisaha').doc(newAd.id).set(newAd.toJson());

    // Kullanıcının ilanını hemen görebilmesi için filtreyi ilana uygun ilçeye ayarla
    final activeDistrict = ref.read(selectedDistrictProvider);
    if (activeDistrict != 'Diyarbakır' && activeDistrict != _selectedDistrict) {
      ref.read(selectedDistrictProvider.notifier).setDistrict(_selectedDistrict);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Halı saha ilanınız başarıyla yayınlandı.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rakip / Oyuncu İlanı Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'İlan Başlığı *',
                  hintText: 'Örn: 7v7 Çarşamba Gece Maçına Rakip Arıyoruz',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Başlık yazmalısınız' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(labelText: 'İlçe *'),
                items: kDistricts
                    .where((d) => d != 'Diyarbakır')
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDistrict = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pitchController,
                decoration: const InputDecoration(
                  labelText: 'Halı Saha Adı *',
                  hintText: 'Örn: Seyrantepe Olimpik Tesisleri',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Saha adı zorunlu' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Maç Tarihi *',
                        hintText: 'Örn: 29 Temmuz Çarşamba',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Tarih zorunlu' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Maç Saati *',
                        hintText: 'Örn: 22:00 - 23:00',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Saat zorunlu' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _missingController,
                decoration: const InputDecoration(
                  labelText: 'Aranan Durum *',
                  hintText: 'Örn: Rakip Takım Arıyoruz veya 2 Kaleci/Oyuncu Arıyoruz',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Bu alan zorunlu' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kişi Başı Ücret (TL)',
                        hintText: '0 yazarsanız ücretsiz görünür',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'İletişim Telefonu *',
                        hintText: 'Örn: 0532 111 22 33',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Telefon zorunlu' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.send),
                  label: const Text('İlanı Yayınla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
