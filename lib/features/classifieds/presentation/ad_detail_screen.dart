import '../../../core/safety/ugc_safety_widgets.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/districts.dart';
import '../../../core/widgets/sub_page_pop_scope.dart';
import '../../../core/widgets/app_image.dart';
import 'ad_provider.dart';
import 'ads_list_screen.dart';
import '../domain/ad_model.dart';

class AdDetailScreen extends ConsumerStatefulWidget {
  final String adId;

  const AdDetailScreen({super.key, required this.adId});

  @override
  ConsumerState<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends ConsumerState<AdDetailScreen> {
  int _currentImageIndex = 0;

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showAdForm(BuildContext context, AdModel adItem) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: adItem.title);
    final descriptionController = TextEditingController(text: adItem.description);
    final priceController = TextEditingController(text: adItem.price.toString());
    final ownerNameController = TextEditingController(text: adItem.ownerName);
    final contactController = TextEditingController(text: adItem.contactPhone);
    final List<String> imageUrlsList = List.generate(
      3,
      (i) => i < adItem.imageUrls.length ? adItem.imageUrls[i] : '',
    );
    String selectedCategory = adItem.category;
    String selectedDistrict = adItem.district;
    String selectedCondition = adItem.condition;

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
                        'İlanı Düzenle',
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
                              value: AdsListScreen.kAdCategories.contains(selectedCategory)
                                  ? selectedCategory
                                  : AdsListScreen.kAdCategories.first,
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: AdsListScreen.kAdCategories.map((cat) {
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
                                          maxWidth: 800,
                                          maxHeight: 800,
                                          imageQuality: 50,
                                        );
                                        if (image != null) {
                                          final bytes = await image.readAsBytes();
                                          final base64Str = base64Encode(bytes);
                                          final mimeType = image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
                                          setModalState(() {
                                            imageUrlsList[index] = 'data:$mimeType;base64,$base64Str';
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
                                final updatedAd = AdModel(
                                  id: adItem.id,
                                  title: titleController.text.trim(),
                                  description: descriptionController.text.trim(),
                                  category: selectedCategory,
                                  district: selectedDistrict,
                                  price: double.parse(priceController.text.trim()),
                                  date: adItem.date,
                                  imageUrls: validImages,
                                  contactPhone: contactController.text.trim(),
                                  ownerName: ownerNameController.text.trim(),
                                  ownerEmail: adItem.ownerEmail,
                                  status: adItem.status,
                                  condition: selectedCondition,
                                );
                                await FirebaseFirestore.instance.collection('ads').doc(updatedAd.id).set(updatedAd.toJson());
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              } catch (err) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hata: $err'), backgroundColor: Colors.red),
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
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İlanı Sil'),
          content: const Text('Bu satış ilanını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('ads').doc(id).delete();
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
    final adsAsync = ref.watch(adsListProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return adsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Hata: $err'))),
      data: (ads) {
        final adIndex = ads.indexWhere((element) => element.id == widget.adId);
        if (adIndex == -1) {
          return const Scaffold(body: Center(child: Text('İlan bulunamadı.')));
        }
        final ad = ads[adIndex];
        final canEdit = authState.isAdmin ||
            (authState.isAuthenticated && authState.email != null && ad.ownerEmail == authState.email);

        return Scaffold(
            appBar: AppBar(
              title: const Text('İlan Detayı'),
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
                  onPressed: () => _showAdForm(context, ad),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ad.id),
                ),
              ],
              if (!canEdit)
                UgcSafetyActionMenu(
                  contentType: 'İlan',
                  contentId: ad.id,
                  contentTitle: ad.title,
                  reportedUserEmail: ad.ownerEmail ?? '',
                  reportedUserName: ad.ownerName,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Hero(
                    tag: 'ad-image-${ad.id}',
                    child: PageView.builder(
                      itemCount: ad.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return AppImage(
                          path: ad.imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                ),
                if (ad.imageUrls.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        ad.imageUrls.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? theme.colorScheme.primary
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ad.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currencyFormatter.format(ad.price),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ad.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ad.condition == 'Sıfır' ? Colors.green.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ad.condition == 'Sıfır' ? '✨ Sıfır Ürün' : '🔄 İkinci El',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ad.condition == 'Sıfır' ? Colors.green.shade800 : Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        ad.district,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        ad.date,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Açıklama',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ad.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surface
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          radius: 24,
                          child: Icon(Icons.person, size: 28, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad.ownerName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bireysel Satıcı',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _makeCall(ad.contactPhone),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Ara'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    },
  );
  }
}
