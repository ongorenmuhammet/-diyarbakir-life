class NewsModel {
  final String id;
  final String title;
  final String summary;
  final String category; // Genel, Belediye, Kültür, Spor
  final String district; // Diyarbakır, Bismil
  final String source;
  final String coverImageUrl;
  final List<String> imageUrls;
  final String date;
  final String content;
  final bool isFeatured;

  const NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    this.district = 'Diyarbakır',
    required this.source,
    required this.coverImageUrl,
    this.imageUrls = const [],
    required this.date,
    required this.content,
    this.isFeatured = false,
  });

  List<String> get allImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (coverImageUrl.isNotEmpty) return [coverImageUrl];
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'category': category,
      'district': district,
      'source': source,
      'coverImageUrl': coverImageUrl,
      'imageUrls': imageUrls,
      'date': date,
      'content': content,
      'isFeatured': isFeatured,
    };
  }

  factory NewsModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final rawImages = json['imageUrls'] != null
        ? List<String>.from((json['imageUrls'] as List).map((e) => e.toString()))
        : <String>[];
    final cover = json['coverImageUrl']?.toString() ?? '';

    String parsedDate = '';
    final rawDate = json['date'];
    if (rawDate != null) {
      if (rawDate is String) {
        parsedDate = rawDate;
      } else {
        try {
          final dynamic dynDate = rawDate;
          final dt = dynDate.toDate != null ? dynDate.toDate() as DateTime : DateTime.now();
          parsedDate = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
        } catch (_) {
          parsedDate = rawDate.toString();
        }
      }
    }
    if (parsedDate.isEmpty) {
      final now = DateTime.now();
      parsedDate = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    }

    return NewsModel(
      id: json['id']?.toString() ?? docId ?? 'news_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Diyarbakır Güncel Gelişme',
      summary: json['summary']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Genel',
      district: json['district']?.toString() ?? 'Diyarbakır',
      source: json['source']?.toString() ?? 'Diyarbakır Yerel Yaşam',
      coverImageUrl: cover,
      imageUrls: rawImages.isNotEmpty ? rawImages : (cover.isNotEmpty ? [cover] : []),
      date: parsedDate,
      content: json['content']?.toString() ?? json['summary']?.toString() ?? '',
      isFeatured: json['isFeatured'] == true || json['isFeatured'] == 'true',
    );
  }
}

const List<NewsModel> defaultDiyarbakirNews = [
  NewsModel(
    id: 'news-fallback-1',
    title: 'Tarihi Diyarbakır Surları ve Hevsel Bahçeleri Ziyaretçi Akınına Uğruyor',
    summary: 'UNESCO Dünya Kültür Mirası listesinde yer alan kadim Diyarbakır Surları ve Hevsel Bahçeleri, bu sezon yerli ve yabancı turistlerin yoğun ilgisini çekiyor.',
    category: 'Kültür',
    district: 'Diyarbakır',
    source: 'Kültür & Turizm Bülteni',
    coverImageUrl: 'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?w=800',
    imageUrls: ['https://images.unsplash.com/photo-1596178065887-1198b6148b2b?w=800'],
    date: 'Bugün',
    content: 'Diyarbakır Valiliği ve Büyükşehir Belediyesi iş birliğiyle sürdürülen restorasyon çalışmalarının ardından tarihi surlar ve burçlar yeniden ışıldıyor. Kültür turlarının gözdesi haline gelen Sur içi bölgesi, kentin kültürel ve ekonomik canlılığına büyük katkı sağlıyor.',
    isFeatured: true,
  ),
  NewsModel(
    id: 'news-fallback-2',
    title: 'Bismil Ovası\'nda Bereketli Pamuk ve Buğday Hasadı Devam Ediyor',
    summary: 'Güneydoğu\'nun en verimli tarım arazilerine sahip Bismil ilçesinde çiftçiler yeni hasat sezonundan yüksek rekolte bekliyor.',
    category: 'Genel',
    district: 'Bismil',
    source: 'Bismil Tarım Gündemi',
    coverImageUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=800',
    imageUrls: ['https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=800'],
    date: 'Dün',
    content: 'Modern sulama sistemlerinin yaygınlaşmasıyla birlikte Bismil ovasında verim rekorları kırılıyor. İlçe Tarım Müdürlüğü yetkilileri, sürdürülebilir tarım teknikleri ile çiftçilere tam destek sağlandığını bildirdi.',
    isFeatured: true,
  ),
  NewsModel(
    id: 'news-fallback-3',
    title: 'Diyarbakır Şehir İçi Ulaşımında Yeni Çevre Dostu Otobüsler Hizmete Girdi',
    summary: 'Büyükşehir Belediyesi Ulaşım Daire Başkanlığı, kent içi trafiği rahatlatmak amacıyla modern ve engelli erişimine uygun yeni otobüsleri sefere koydu.',
    category: 'Belediye',
    district: 'Diyarbakır',
    source: 'Büyükşehir Basın Merkezi',
    coverImageUrl: 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800',
    imageUrls: ['https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800'],
    date: '2 gün önce',
    content: 'Yeni araç filosu, özellikle üniversite kampüsü, şehir hastanesi ve merkez ilçeler arasındaki yoğun hatlarda sefer sıklığını artırarak vatandaşlara konforlu bir ulaşım sunuyor.',
    isFeatured: false,
  ),
  NewsModel(
    id: 'news-fallback-4',
    title: 'Amedspor Yeni Sezon Hazırlıklarını Şampiyonluk Hedefiyle Sürdürüyor',
    summary: 'Kentin gururu Amedspor, tesislerinde sürdürdüğü antrenmanlarla yeni lige galibiyet parolasıyla hazırlanıyor.',
    category: 'Spor',
    district: 'Diyarbakır',
    source: 'Diyarbakır Spor Servisi',
    coverImageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
    imageUrls: ['https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800'],
    date: '3 gün önce',
    content: 'Teknik direktör ve futbolcuların moralinin yüksek olduğu kampta, taraftarların stadyumu doldurarak takıma tam destek vermesi bekleniyor.',
    isFeatured: false,
  ),
  NewsModel(
    id: 'news-fallback-5',
    title: 'Tarihi Ongözlü Köprü ve Dicle Vadisi Çevre Düzenleme Projesi Tamamlandı',
    summary: 'Diyarbakır\'ın simgelerinden tarihi Ongözlü Köprü çevresindeki rekreasyon alanları ve yürüyüş yolları vatandaşların hizmetine açıldı.',
    category: 'Kültür',
    district: 'Diyarbakır',
    source: 'Kent ve Yaşam Bülteni',
    coverImageUrl: 'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?w=800',
    imageUrls: ['https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?w=800'],
    date: '4 gün önce',
    content: 'Dicle Nehri kıyısında yapılan yeşillendirme, aydınlatma ve dinlenme alanları, kentin doğal güzelliğini gözler önüne seriyor.',
    isFeatured: true,
  ),
];
