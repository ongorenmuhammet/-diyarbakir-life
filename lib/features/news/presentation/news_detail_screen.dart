import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/sub_page_pop_scope.dart';
import 'news_provider.dart';
import '../domain/news_model.dart';

class NewsDetailScreen extends ConsumerWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  void _showNewsForm(BuildContext context, WidgetRef ref, NewsModel newsItem) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: newsItem.title);
    final summaryController = TextEditingController(text: newsItem.summary);
    final sourceController = TextEditingController(text: newsItem.source);
    final List<String> newsImagesList = List.generate(
      3,
      (i) => (i < newsItem.allImages.length) ? newsItem.allImages[i] : '',
    );
    final contentController = TextEditingController(text: newsItem.content);
    String selectedCategory = newsItem.category;
    bool isFeatured = newsItem.isFeatured;

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
                        'Haberi Düzenle',
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
                                          maxWidth: 800,
                                          maxHeight: 800,
                                          imageQuality: 50,
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
                                id: newsItem.id,
                                title: titleController.text.trim(),
                                summary: summaryController.text.trim(),
                                category: selectedCategory,
                                source: sourceController.text.trim(),
                                coverImageUrl: validImages.first,
                                imageUrls: validImages,
                                date: newsItem.date,
                                content: contentController.text.trim(),
                                isFeatured: isFeatured,
                              );
                              FirebaseFirestore.instance.collection('news').doc(updatedItem.id).set(updatedItem.toJson());
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
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Haberi Sil'),
          content: const Text('Bu haberi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('news').doc(id).delete();
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
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsListProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return newsAsync.when(
      data: (newsList) {
        final allList = [...newsList, ...defaultDiyarbakirNews];
        final itemIndex = allList.indexWhere((element) => element.id == newsId);
        final item = itemIndex != -1 ? allList[itemIndex] : defaultDiyarbakirNews.first;

        return Scaffold(
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Parallax Image Header
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.4),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                    ),
                  ),
                actions: authState.isAdmin
                    ? [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.4),
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                              onPressed: () => _showNewsForm(context, ref, item),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.4),
                            child: IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () => _confirmDelete(context, ref, item.id),
                            ),
                          ),
                        ),
                      ]
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: item.allImages.length > 1
                      ? Stack(
                          children: [
                            PageView.builder(
                              itemCount: item.allImages.length,
                              itemBuilder: (context, index) {
                                return AppImage(
                                  path: item.allImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '📸 ${item.allImages.length} Görsel',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Hero(
                          tag: 'news-image-${item.id}',
                          child: AppImage(
                            path: item.coverImageUrl.isNotEmpty ? item.coverImageUrl : (item.allImages.isNotEmpty ? item.allImages.first : ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              
              // Article Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.category,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.date,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          height: 1.3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            radius: 18,
                            child: Icon(Icons.source, size: 18, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.source,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Haber Kaynağı',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 16),
                      Text(
                        item.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
            );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Haber Detayı')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Haber detayları yüklenirken bir sorun oluştu. Lütfen bağlantınızı kontrol ediniz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
