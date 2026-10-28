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

const List<NewsModel> defaultDiyarbakirNews = [];
