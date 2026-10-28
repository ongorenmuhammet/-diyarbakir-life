import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/notifications/notification_provider.dart';
import 'news_provider.dart';
import '../domain/news_model.dart';
import '../../../core/constants/districts.dart';

class NewsListScreen extends ConsumerWidget {
  const NewsListScreen({super.key});

  void _showNewsForm(BuildContext context, WidgetRef ref, [NewsModel? newsItem]) {
    final isEdit = newsItem != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: newsItem?.title);
    final summaryController = TextEditingController(text: newsItem?.summary);
    final sourceController = TextEditingController(text: newsItem?.source ?? '');
    final List<String> newsImagesList = List.generate(
      3,
      (i) => (newsItem != null && i < newsItem.allImages.length) ? newsItem.allImages[i] : '',
    );
    final contentController = TextEditingController(text: newsItem?.content);
    String selectedCategory = newsItem?.category ?? 'Genel';
    String selectedNewsDistrict = newsItem?.district ?? 'Diyarbakır';
    bool isFeatured = newsItem?.isFeatured ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final authState = ref.read(authProvider);
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
                        isEdit ? 'Haberi Düzenle' : 'Yeni Haber Ekle',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Haber Başlığı',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Başlık boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: summaryController,
                        decoration: InputDecoration(
                          labelText: 'Haber Özeti (Kısa)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Özet boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Genel', child: Text('Genel')),
                          DropdownMenuItem(value: 'Belediye', child: Text('Belediye')),
                          DropdownMenuItem(value: 'Kültür', child: Text('Kültür')),
                          DropdownMenuItem(value: 'Spor', child: Text('Spor')),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedCategory = val;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedNewsDistrict,
                        decoration: InputDecoration(
                          labelText: 'Haber Bölgesi',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Diyarbakır', child: Text('Diyarbakır (Genel)')),
                          DropdownMenuItem(value: 'Bismil', child: Text('Bismil')),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedNewsDistrict = val;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: sourceController,
                        decoration: InputDecoration(
                          labelText: 'Haber Kaynağı',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Kaynak boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Haber Görselleri (En fazla 3 adet)',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(3, (index) {
                          final hasImg = newsImagesList[index].isNotEmpty;
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
                                          final base64Str = base64Encode(bytes);
                                          final mimeType = image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
                                          setModalState(() {
                                            newsImagesList[index] = 'data:$mimeType;base64,$base64Str';
                                          });
                                        }
                                      } catch (_) {}
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: hasImg
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: AppImage(
                                              path: newsImagesList[index],
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
                                            newsImagesList[index] = '';
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
                      if (newsImagesList.every((img) => img.isEmpty)) ...[
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

                      TextFormField(
                        controller: contentController,
                        decoration: InputDecoration(
                          labelText: 'Haber Detay İçeriği',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 6,
                        validator: (value) => value == null || value.trim().isEmpty ? 'İçerik boş bırakılamaz' : null,
                      ),
                      if (authState.isAdmin) ...[
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: theme.colorScheme.primary.withOpacity(0.05),
                          title: const Text('⭐ Öne Çıkan Haber (Ana Sayfa)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Bu haberi ana sayfadaki öne çıkan haberler alanında göster.', style: TextStyle(fontSize: 12)),
                          value: isFeatured,
                          onChanged: (val) {
                            setModalState(() {
                              isFeatured = val;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final validImages = newsImagesList.where((img) => img.isNotEmpty).toList();
                            if (validImages.isEmpty) {
                              setModalState(() {});
                              return;
                            }
                            if (formKey.currentState!.validate()) {
                              final updatedItem = NewsModel(
                                id: isEdit ? newsItem.id : 'news-${DateTime.now().millisecondsSinceEpoch}',
                                title: titleController.text.trim(),
                                summary: summaryController.text.trim(),
                                category: selectedCategory,
                                district: selectedNewsDistrict,
                                source: sourceController.text.trim(),
                                coverImageUrl: validImages.first,
                                imageUrls: validImages,
                                date: isEdit ? newsItem.date : 'Bugün',
                                content: contentController.text.trim(),
                                isFeatured: isFeatured,
                              );
                              if (isEdit) {
                                FirebaseFirestore.instance.collection('news').doc(updatedItem.id).set(updatedItem.toJson());
                              } else {
                                FirebaseFirestore.instance.collection('news').doc(updatedItem.id).set(updatedItem.toJson());
                                FirebaseFirestore.instance.collection('broadcast_notifications').add({
                                  'type': 'news',
                                  'title': updatedItem.title,
                                  'summary': updatedItem.summary,
                                  'newsId': updatedItem.id,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                              }
                              Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(newsCategoryFilterProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentDistrict = ref.watch(selectedDistrictProvider);
    final displayTitle = currentDistrict == 'Bismil' ? 'Bismil Haberleri' : 'Diyarbakır Haberleri';

    final categories = ['Hepsi', 'Belediye', 'Kültür', 'Spor'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(displayTitle),
      ),
      floatingActionButton: authState.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showNewsForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Haber Ekle'),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) => ref.read(newsSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Haberlerde ara...',
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
          
          // Category Selector
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(newsCategoryFilterProvider.notifier).state = category;
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),
          
          // News Feed
          Expanded(
            child: ref.watch(filteredNewsProvider).when(
              data: (newsList) {
                if (newsList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.newspaper_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Haber bulunamadı.',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final item = newsList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildNewsCard(context, ref, item),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz haber bulunmuyor.',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, WidgetRef ref, NewsModel item) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    
    return InkWell(
      onTap: () => context.push('/news/${item.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with optional badge
            Stack(
              children: [
                Hero(
                  tag: 'news-image-${item.id}',
                  child: AppImage(
                    path: item.coverImageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (item.isFeatured)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Öne Çıkan',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (authState.isAdmin)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              item.isFeatured ? Icons.star : Icons.star_border,
                              color: item.isFeatured ? Colors.amber : Colors.white,
                              size: 20,
                            ),
                            tooltip: item.isFeatured ? 'Öne Çıkarılanlardan Kaldır' : 'Öne Çıkar',
                            onPressed: () {
                              FirebaseFirestore.instance.collection('news').doc(item.id).update({
                                'isFeatured': !item.isFeatured,
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                            tooltip: 'Haberi Düzenle',
                            onPressed: () => _showNewsForm(context, ref, item),
                          ),
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                            tooltip: 'Haberi Sil',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Haberi Sil'),
                                  content: const Text('Bu haberi silmek istediğinize emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('İptal'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                FirebaseFirestore.instance.collection('news').doc(item.id).delete();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            // Text Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        item.date,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.source_outlined, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Kaynak: ${item.source}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Devamını Oku',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: theme.colorScheme.primary),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
