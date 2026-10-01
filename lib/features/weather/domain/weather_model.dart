class DailyForecast {
  final String dayName;
  final int temp;
  final String condition;
  final String icon;

  const DailyForecast({
    required this.dayName,
    required this.temp,
    required this.condition,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'temp': temp,
      'condition': condition,
      'icon': icon,
    };
  }

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      dayName: json['dayName'] as String? ?? 'Bugün',
      temp: (json['temp'] as num? ?? 25).toInt(),
      condition: json['condition'] as String? ?? 'Güneşli',
      icon: json['icon'] as String? ?? 'sunny',
    );
  }
}

class WeatherModel {
  final String district;
  final int temp;
  final int feelsLike;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String icon;
  final List<DailyForecast> forecast;

  const WeatherModel({
    required this.district,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.icon,
    required this.forecast,
  });

  Map<String, dynamic> toJson() {
    return {
      'district': district,
      'temp': temp,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'condition': condition,
      'icon': icon,
      'forecast': forecast.map((f) => f.toJson()).toList(),
    };
  }

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      district: json['district'] as String? ?? 'Diyarbakır',
      temp: (json['temp'] as num? ?? 25).toInt(),
      feelsLike: (json['feelsLike'] as num? ?? 25).toInt(),
      humidity: (json['humidity'] as num? ?? 40).toInt(),
      windSpeed: (json['windSpeed'] as num? ?? 10.0).toDouble(),
      condition: json['condition'] as String? ?? 'Açık, Güneşli',
      icon: json['icon'] as String? ?? 'sunny',
      forecast: (json['forecast'] as List<dynamic>?)
              ?.map((item) => DailyForecast.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
