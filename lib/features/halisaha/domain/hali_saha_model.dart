class HaliSahaAdModel {
  final String id;
  final String title;
  final String district;
  final String pitchName;
  final String matchDate;
  final String matchTime;
  final String missingCount; // e.g. 'Rakip Takım Arıyoruz' or '2 Kaleci/Oyuncu Arıyoruz'
  final double pricePerPerson;
  final String contactPhone;
  final String ownerName;
  final String? userEmail;
  final String createdAt;
  final String status; // 'approved' or 'pending'

  const HaliSahaAdModel({
    required this.id,
    required this.title,
    required this.district,
    required this.pitchName,
    required this.matchDate,
    required this.matchTime,
    required this.missingCount,
    required this.pricePerPerson,
    required this.contactPhone,
    required this.ownerName,
    this.userEmail,
    required this.createdAt,
    this.status = 'approved',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'district': district,
      'pitchName': pitchName,
      'matchDate': matchDate,
      'matchTime': matchTime,
      'missingCount': missingCount,
      'pricePerPerson': pricePerPerson,
      'contactPhone': contactPhone,
      'ownerName': ownerName,
      'userEmail': userEmail,
      'createdAt': createdAt,
      'status': status,
    };
  }

  factory HaliSahaAdModel.fromJson(Map<String, dynamic> json) {
    return HaliSahaAdModel(
      id: json['id'] as String,
      title: json['title'] as String,
      district: json['district'] as String? ?? 'Diyarbakır',
      pitchName: json['pitchName'] as String? ?? '',
      matchDate: json['matchDate'] as String? ?? '',
      matchTime: json['matchTime'] as String? ?? '',
      missingCount: json['missingCount'] as String? ?? 'Rakip Takım Arıyoruz',
      pricePerPerson: (json['pricePerPerson'] as num? ?? 0.0).toDouble(),
      contactPhone: json['contactPhone'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      userEmail: json['userEmail'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      status: json['status'] as String? ?? 'approved',
    );
  }
}
