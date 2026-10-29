import '../../../core/utils/image_compress_helper.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/districts.dart';
import '../../../core/widgets/app_image.dart';
import 'ad_provider.dart';
import '../domain/ad_model.dart';

class AdsListScreen extends ConsumerWidget {
  const AdsListScreen({super.key});

  void _showAdForm(BuildContext context, WidgetRef ref, [AdModel? adItem]) {
    final isEdit = adItem != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: adItem?.title);
    final descriptionController = TextEditingController(text: adItem?.description);
    final priceController = TextEditingController(text: adItem?.price.toString());
    final ownerNameController = TextEditingController(text: adItem?.ownerName ?? '');
    final contactController = TextEditingController(text: adItem?.contactPhone ?? '');
    final List<String> imageUrlsList = List.generate(
      3,
      (i) => (adItem != null && i < adItem.imageUrls.length) ? adItem.imageUrls[i] : '',
    );
    String selectedCategory = adItem?.category ?? kAdCategories.first;
    String selectedDistrict = adItem?.district ?? ref.read(selectedDistrictProvider);
    String selectedCondition = adItem?.condition ?? 'İkinci El';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        isEdit ? 'İlanı Düzenle' : 'Yeni İlan Ekle',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'İlan Başlığı',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Başlık boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'İlan Açıklaması',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 4,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Açıklama boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: kAdCategories.contains(selectedCategory) ? selectedCategory : kAdCategories.first,
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: kAdCategories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) selectedCategory = val;
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              decoration: InputDecoration(
                                labelText: 'Fiyat (TL)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Fiyat boş bırakılamaz';
                                if (double.tryParse(value) == null) return 'Geçerli bir rakam girin';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCondition,
                              decoration: InputDecoration(
                                labelText: 'Ürünün Durumu',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'İkinci El', child: Text('🔄 İkinci El')),
                                DropdownMenuItem(value: 'Sıfır', child: Text('✨ Sıfır')),
                              ],
                              onChanged: (val) {
                                if (val != null) selectedCondition = val;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'İlan Görselleri (En fazla 3 adet)',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(3, (index) {
                          final hasImg = imageUrlsList[index].isNotEmpty;
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: index < 2 ? 8.0 : 0),
                              height: 100,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (index == 0 && !hasImg)
                                      ? Colors.red.withOpacity(0.6)
                                      : theme.colorScheme.primary.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      try {
                                        final picker = ImagePicker();
                                        final XFile? image = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          maxWidth: 480,
                                          maxHeight: 480,
                                          imageQuality: 35,
                                        );
                                        if (image != null) {
                                          final bytes = await image.readAsBytes();
                                          final compressedBase64 = await ImageCompressHelper.compressAndEncodeBase64(bytes);
                                          setModalState(() {
                                            imageUrlsList[index] = compressedBase64;
                                          });
                                        }
                                      } catch (_) {}
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: hasImg
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: AppImage(
                                              path: imageUrlsList[index],
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_a_photo_outlined,
                                                  size: 24,
                                                  color: theme.colorScheme.primary,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  index == 0 ? 'Kapak *' : '${index + 1}. Görsel',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  if (hasImg)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            imageUrlsList[index] = '';
                                          });
                                        },
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red.shade700,
                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      if (imageUrlsList.every((img) => img.isEmpty)) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            'Lütfen en az 1 kapak görseli ekleyin',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: ownerNameController,
                              decoration: InputDecoration(
                                labelText: 'Satıcı İsim',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'İsim boş bırakılamaz' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: contactController,
                              decoration: InputDecoration(
                                labelText: 'Telefon No',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Telefon boş bırakılamaz' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final validImages = imageUrlsList.where((img) => img.isNotEmpty).toList();
                            if (validImages.isEmpty) {
                              setModalState(() {});
                              return;
                            }
                            if (formKey.currentState!.validate()) {
                              try {
                                final auth = ref.read(authProvider);
                                final isPending = !auth.isAdmin && (!isEdit || adItem.status == 'pending');
                                final updatedAd = AdModel(
                                  id: isEdit ? adItem.id : 'ad-${DateTime.now().millisecondsSinceEpoch}',
                                  title: titleController.text.trim(),
                                  description: descriptionController.text.trim(),
                                  category: selectedCategory,
                                  district: selectedDistrict,
                                  price: double.parse(priceController.text.trim()),
                                  date: isEdit ? adItem.date : 'Bugün',
                                  imageUrls: validImages,
                                  contactPhone: contactController.text.trim(),
                                  ownerName: ownerNameController.text.trim(),
                                  ownerEmail: isEdit ? adItem.ownerEmail : auth.email,
                                  status: isPending ? 'pending' : (isEdit ? adItem.status : 'approved'),
                                  condition: selectedCondition,
                                );
                                await FirebaseFirestore.instance.collection('ads').doc(updatedAd.id).set(updatedAd.toJson());
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  if (isPending) {
                                    _showApprovalWaitingDialog(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('İlanınız başarıyla yayınlandı.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              } catch (err) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hata: $err'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
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
            'İlanınız yöneticimizin onayına sunulmuştur. Yönetici onayladıktan hemen sonra yayında olacaktır.',
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

  static const List<String> kAdCategories = [
    'İkinci El Ev Eşyası',
    'Vasıta & Otomobil',
    'Emlak & Gayrimenkul',
    'Elektronik & Telefon',
    'Giyim & Aksesuar',
    'Anne & Bebek / Oyuncak',
    'Spor & Hobi',
    'Tarım & Hayvancılık',
    'İş Makineleri & Sanayi',
    'Diğer İlanlar',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(filteredAdsProvider);
    final selectedCategory = ref.watch(adCategoryFilterProvider);
    final selectedCondition = ref.watch(adConditionFilterProvider);
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ['Hepsi', ...kAdCategories];
    final currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('Satılık İlanlar'),
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
              onPressed: () => _showAdForm(context, ref),
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
              onChanged: (val) => ref.read(adSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: '$selectedDistrict ilanlarında ara...',
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
          
          // Category & Condition Dropdown Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: categories.contains(selectedCategory) ? selectedCategory : 'Hepsi',
                        isExpanded: true,
                        icon: const Icon(Icons.category_outlined, size: 20),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        dropdownColor: theme.colorScheme.surface,
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(adCategoryFilterProvider.notifier).state = val;
                          }
                        },
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat == 'Hepsi' ? '🏷️ Tüm Kategoriler' : '🏷️ $cat', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCondition,
                        isExpanded: true,
                        icon: const Icon(Icons.filter_list, size: 20),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        dropdownColor: theme.colorScheme.surface,
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(adConditionFilterProvider.notifier).state = val;
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'Tümü', child: Text('✨ Tüm Durumlar', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'İkinci El', child: Text('🔄 İkinci El', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Sıfır', child: Text('✨ Sıfır', overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Grid list
          Expanded(
            child: adsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('İlanlar yüklenemedi: $err')),
              data: (ads) {
                if (ads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            '$selectedDistrict ilçesinde aktif ilan bulunmamaktadır.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return _buildAdGridCard(context, ad, currencyFormatter);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdGridCard(BuildContext context, AdModel ad, NumberFormat formatter) {
    return InkWell(
      onTap: () => context.push('/classifieds/${ad.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'ad-image-${ad.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AppImage(
                      path: ad.imageUrls.first,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ad.category,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: ad.condition == 'Sıfır' ? Colors.green.shade700 : Colors.amber.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ad.condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatter.format(ad.price),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${ad.district} • ${ad.date}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
