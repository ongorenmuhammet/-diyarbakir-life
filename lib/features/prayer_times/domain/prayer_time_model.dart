class PrayerTimeModel {
  final String district;
  final String date;
  final String imsak;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;

  const PrayerTimeModel({
    required this.district,
    required this.date,
    required this.imsak,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
  });

  Map<String, dynamic> toJson() {
    return {
      'district': district,
      'date': date,
      'imsak': imsak,
      'gunes': gunes,
      'ogle': ogle,
      'ikindi': ikindi,
      'aksam': aksam,
      'yatsi': yatsi,
    };
  }

  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) {
    return PrayerTimeModel(
      district: json['district'] as String? ?? 'Diyarbakır',
      date: json['date'] as String? ?? '',
      imsak: json['imsak'] as String? ?? '04:15',
      gunes: json['gunes'] as String? ?? '05:45',
      ogle: json['ogle'] as String? ?? '12:30',
      ikindi: json['ikindi'] as String? ?? '16:10',
      aksam: json['aksam'] as String? ?? '19:45',
      yatsi: json['yatsi'] as String? ?? '21:05',
    );
  }

  factory PrayerTimeModel.fromAladhanJson(Map<String, dynamic> json, String district) {
    final timings = json['data']['timings'];
    final dateStr = json['data']['date']?['gregorian']?['date'] ?? '';
    return PrayerTimeModel(
      district: district,
      date: dateStr,
      imsak: timings['Fajr'] ?? '04:15',
      gunes: timings['Sunrise'] ?? '05:45',
      ogle: timings['Dhuhr'] ?? '12:30',
      ikindi: timings['Asr'] ?? '16:10',
      aksam: timings['Maghrib'] ?? '19:45',
      yatsi: timings['Isha'] ?? '21:05',
    );
  }
}
