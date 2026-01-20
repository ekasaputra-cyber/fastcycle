// lib/models/weather_model.dart

class WeatherModel {
  final String cityName;
  final double temp;
  final String description;
  final String iconCode;
  final int humidity;
  final double windSpeed;
  final DateTime date;
  
  // Data Lokasi & Waktu
  final double lat;
  final double lon;
  final int timezoneOffset; // Offset detik dari UTC

  // Data Detail
  final int pressure;
  final int visibility;
  final int sunrise;
  final int sunset;
  
  // Data Tambahan (Mutable agar bisa diisi terpisah)
  int aqi; 
  double rainChance; // Probability of Precipitation (0.0 - 1.0)

  WeatherModel({
    required this.cityName,
    required this.temp,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.date,
    required this.lat,
    required this.lon,
    required this.timezoneOffset,
    required this.pressure,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    this.aqi = 0,
    this.rainChance = 0.0,
  });

  // Factory untuk Current Weather (/weather)
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temp: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      lat: (json['coord']['lat'] as num).toDouble(),
      lon: (json['coord']['lon'] as num).toDouble(),
      timezoneOffset: json['timezone'] ?? 0,
      pressure: json['main']['pressure'] ?? 0,
      visibility: json['visibility'] ?? 0,
      sunrise: json['sys']['sunrise'] ?? 0,
      sunset: json['sys']['sunset'] ?? 0,
      aqi: 0, // Diisi nanti lewat API terpisah
      rainChance: 0.0,
    );
  }

  // Factory untuk Forecast Item (/forecast)
  factory WeatherModel.fromForecastJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: '', 
      temp: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      lat: 0, lon: 0, // Tidak tersedia di item forecast
      timezoneOffset: 0,
      pressure: json['main']['pressure'] ?? 0,
      visibility: json['visibility'] ?? 0,
      sunrise: 0, sunset: 0,
      aqi: 0,
      rainChance: (json['pop'] as num).toDouble(), // Ambil peluang hujan
    );
  }

  // Hitung Titik Embun Manual
  double get dewPoint => temp - ((100 - humidity) / 5);
}

// Model ringkas untuk UI Harian
class DailySummary {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String iconCode;
  final double avgRainChance;

  DailySummary({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.iconCode,
    required this.avgRainChance,
  });
}