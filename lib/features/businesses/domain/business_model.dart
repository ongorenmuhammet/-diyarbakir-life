class BusinessMenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // e.g. 'Yemekler', 'Tatlılar', 'İçecekler'
  final String? imageUrl;

  const BusinessMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  factory BusinessMenuItem.fromJson(Map<String, dynamic> json) {
    return BusinessMenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String? ?? 'Genel',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class BusinessModel {
  final String id;
  final String name;
  final String category; // e.g. 'Restoran & Kafe', 'Tatlı & Pastane', 'Fırın & Ciğerci'
  final String district;
  final double rating;
  final int reviewCount;
  final String address;
  final String phone;
  final String coverImageUrl;
  final String logoUrl;
  final String description;
  final bool isFeatured;
  final List<BusinessMenuItem> menu;
  final String? ownerEmail;
  final String status; // 'approved' or 'pending'

  const BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.district,
    required this.rating,
    required this.reviewCount,
    required this.address,
    required this.phone,
    required this.coverImageUrl,
    required this.logoUrl,
    required this.description,
    this.isFeatured = false,
    required this.menu,
    this.ownerEmail,
    this.status = 'approved',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'district': district,
      'rating': rating,
      'reviewCount': reviewCount,
      'address': address,
      'phone': phone,
      'coverImageUrl': coverImageUrl,
      'logoUrl': logoUrl,
      'description': description,
      'isFeatured': isFeatured,
      'menu': menu.map((m) => m.toJson()).toList(),
      'ownerEmail': ownerEmail,
      'status': status,
    };
  }

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Restoran & Kafe',
      district: json['district'] as String? ?? 'Diyarbakır',
      rating: (json['rating'] as num? ?? 4.5).toDouble(),
      reviewCount: (json['reviewCount'] as num? ?? 12).toInt(),
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
      menu: (json['menu'] as List<dynamic>?)
              ?.map((item) => BusinessMenuItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      ownerEmail: json['ownerEmail'] as String?,
      status: json['status'] as String? ?? 'approved',
    );
  }
}
