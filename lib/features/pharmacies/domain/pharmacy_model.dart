class PharmacyModel {
  final String id;
  final String name;
  final String district;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String hours; // e.g. "09:00 - Ertesi Gün 09:00"

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.district,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.hours,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'district': district,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'hours': hours,
    };
  }

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      district: json['district'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      hours: json['hours'] as String,
    );
  }

  factory PharmacyModel.fromCollectApiJson(Map<String, dynamic> json) {
    // CollectAPI 'loc' formats: "lat,lng" e.g. "37.9351,40.1782"
    double lat = 0.0;
    double lng = 0.0;
    if (json['loc'] != null && json['loc'].toString().contains(',')) {
      final parts = json['loc'].toString().split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim()) ?? 0.0;
        lng = double.tryParse(parts[1].trim()) ?? 0.0;
      }
    }

    String rawDist = json['dist'] ?? 'Merkez';
    String formattedDist = _capitalizeTurkish(rawDist);

    return PharmacyModel(
      id: json['name'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Bilinmeyen Eczane',
      district: formattedDist,
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      latitude: lat,
      longitude: lng,
      hours: '24 Saat Nöbetçi', // CollectAPI returns current duty pharmacies
    );
  }

  static String _capitalizeTurkish(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase().replaceAll('i̇', 'i').replaceAll('I', 'ı');
    final firstChar = lower.substring(0, 1).toUpperCase().replaceAll('i', 'İ').replaceAll('ı', 'I');
    return firstChar + lower.substring(1);
  }
}
