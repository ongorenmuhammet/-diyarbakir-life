class AdModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String district;
  final double price;
  final String date;
  final List<String> imageUrls;
  final String contactPhone;
  final String ownerName;
  final String? ownerEmail;
  final String status; // 'approved' or 'pending'
  final String condition; // 'Sıfır' or 'İkinci El'

  const AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.district,
    required this.price,
    required this.date,
    required this.imageUrls,
    required this.contactPhone,
    required this.ownerName,
    this.ownerEmail,
    this.status = 'approved',
    this.condition = 'İkinci El',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'district': district,
      'price': price,
      'date': date,
      'imageUrls': imageUrls,
      'contactPhone': contactPhone,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail ?? '',
      'status': status,
      'condition': condition,
    };
  }

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      district: json['district'] as String,
      price: (json['price'] as num).toDouble(),
      date: json['date'] as String,
      imageUrls: List<String>.from(json['imageUrls'] as List),
      contactPhone: json['contactPhone'] as String,
      ownerName: json['ownerName'] as String,
      ownerEmail: json['ownerEmail'] as String?,
      status: json['status'] as String? ?? 'pending',
      condition: json['condition'] as String? ?? 'İkinci El',
    );
  }
}
