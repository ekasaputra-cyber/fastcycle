// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/weather_models.dart';
import '../models/weather_service.dart';
import '../models/weather_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _cityController = TextEditingController();
  
  WeatherModel? _currentWeather;
  List<WeatherModel> _hourlyList = [];
  List<DailySummary> _dailyList = [];
  
  bool _isLoading = true;
  double _weekMinTemp = 0;
  double _weekMaxTemp = 100;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _fetchWeather("Malang"); // Default kota awal
    });
  }

  Future<void> _fetchWeather(String city) async {
    setState(() => _isLoading = true);
    try {
      // 1. Panggil API Current & Forecast
      final results = await Future.wait([
        _weatherService.getCurrentWeather(city),
        _weatherService.getForecast(city),
      ]);

      WeatherModel current = results[0] as WeatherModel;
      List<WeatherModel> forecast = results[1] as List<WeatherModel>;

      // 2. Panggil API AQI menggunakan koordinat dari current weather
      final aqi = await _weatherService.getAirQuality(current.lat, current.lon);
      current.aqi = aqi; // Inject AQI ke model

      // 3. Proses Data
      _processDailyForecast(forecast);
      
      setState(() {
        _currentWeather = current;
        _hourlyList = forecast.take(8).toList(); // Ambil 24 jam ke depan (8 x 3jam)
        _cityController.text = current.cityName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memuat data. Periksa nama kota.")));
    }
  }

  // Logika grouping data 3-jam menjadi harian
  void _processDailyForecast(List<WeatherModel> list) {
    Map<String, List<WeatherModel>> grouped = {};
    for (var item in list) {
      String dateKey = DateFormat('yyyy-MM-dd').format(item.date);
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(item);
    }

    List<DailySummary> summaries = [];
    double gMin = 100, gMax = -100;

    grouped.forEach((key, items) {
      double min = 100, max = -100, pop = 0;
      String icon = items.first.iconCode;
      
      for (var i in items) {
        if (i.temp < min) min = i.temp;
        if (i.temp > max) max = i.temp;
        pop += i.rainChance;
        // Ambil icon siang hari (jam 12) jika ada
        if (i.date.hour == 12) icon = i.iconCode;
      }
      
      // Update global min/max untuk skala bar
      if (min < gMin) gMin = min;
      if (max > gMax) gMax = max;

      summaries.add(DailySummary(
        date: items.first.date,
        minTemp: min, maxTemp: max, iconCode: icon,
        avgRainChance: pop / items.length,
      ));
    });

    _dailyList = summaries.take(5).toList();
    _weekMinTemp = gMin;
    _weekMaxTemp = gMax;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101014), // Background Gelap Pekat
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: _isLoading ? null : DualClockWidget(timezoneOffset: _currentWeather?.timezoneOffset ?? 0),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 30),
                  
                  // --- HEADER CUACA ---
                  Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Image.network('https://openweathermap.org/img/wn/${_currentWeather!.iconCode}@2x.png', height: 80),
                  Text(_currentWeather!.description.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text("${_currentWeather!.temp.toStringAsFixed(0)}°", style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
                    Text(" ${_currentWeather!.cityName}", style: const TextStyle(color: Colors.white70)),
                  ]),
                  
                  const SizedBox(height: 40),

                  // --- HOURLY LIST ---
                  Align(alignment: Alignment.centerLeft, child: Text("Cuaca Hari Ini", style: _headerStyle)),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _hourlyList.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = _hourlyList[index];
                        final isNow = index == 0;
                        return Container(
                          width: 70, padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isNow ? Colors.blueAccent.withValues(alpha: 0.3) : const Color(0xFF1D1E22),
                            borderRadius: BorderRadius.circular(30),
                            border: isNow ? Border.all(color: Colors.blueAccent) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('HH:mm').format(item.date), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Image.network('https://openweathermap.org/img/wn/${item.iconCode}.png', width: 35),
                              Text("${item.temp.toStringAsFixed(0)}°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- DAILY LIST ---
                  Align(alignment: Alignment.centerLeft, child: Text("Ramalan Harian", style: _headerStyle)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1D1E22), borderRadius: BorderRadius.circular(25)),
                    child: Column(
                      children: _dailyList.map((day) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            SizedBox(width: 50, child: Text(DateFormat('EEE', 'id_ID').format(day.date), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Image.network('https://openweathermap.org/img/wn/${day.iconCode}.png', width: 30)),
                            if(day.avgRainChance > 0) Text("${(day.avgRainChance*100).toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                            const SizedBox(width: 10),
                            SizedBox(width: 30, child: Text("${day.minTemp.round()}°", style: const TextStyle(color: Colors.grey))),
                            Expanded(child: TempRangeBar(min: day.minTemp, max: day.maxTemp, weekMin: _weekMinTemp, weekMax: _weekMaxTemp)),
                            SizedBox(width: 30, child: Text("${day.maxTemp.round()}°", textAlign: TextAlign.end, style: const TextStyle(color: Colors.white))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // --- SUN & AQI ---
                  SunAndAqiSection(data: _currentWeather!),
                  const SizedBox(height: 20),
                  
                  // --- DETAIL GRID ---
                  DetailGrid(data: _currentWeather!),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1D1E22), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: _cityController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Cari kota...", hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.blueAccent),
            onPressed: () { FocusScope.of(context).unfocus(); _fetchWeather(_cityController.text); },
          )
        ),
        onSubmitted: (val) => _fetchWeather(val),
      ),
    );
  }

  TextStyle get _headerStyle => const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600);
}