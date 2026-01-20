// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constans.dart';
import '../models/weather_models.dart';

class WeatherService {
  
  // 1. Current Weather
  Future<WeatherModel> getCurrentWeather(String city) async {
    final url = Uri.parse('${AppConstants.baseUrl}/weather?q=$city&appid=${AppConstants.apiKey}&units=metric&lang=id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat cuaca');
    }
  }

  // 2. Forecast 5 Days / 3 Hours
  Future<List<WeatherModel>> getForecast(String city) async {
    final url = Uri.parse('${AppConstants.baseUrl}/forecast?q=$city&appid=${AppConstants.apiKey}&units=metric&lang=id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['list'] as List).map((item) => WeatherModel.fromForecastJson(item)).toList();
    } else {
      throw Exception('Gagal memuat forecast');
    }
  }

  // 3. Air Quality Index (AQI)
  Future<int> getAirQuality(double lat, double lon) async {
    final url = Uri.parse('${AppConstants.baseUrl}/air_pollution?lat=$lat&lon=$lon&appid=${AppConstants.apiKey}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['list'][0]['main']['aqi']; // 1 (Baik) - 5 (Buruk)
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}