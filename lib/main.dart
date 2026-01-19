import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const FastCycleApp());
}

class FastCycleApp extends StatelessWidget {
  const FastCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastCycle',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variabel untuk Waktu
  String _timeString = "";
  String _dateString = "";
  late Timer _timer;

  // Variabel untuk Cuaca
  String _temp = "0";
  String _description = "Loading...";
  String _cityName = "Malang"; // Default kota
  String _iconCode = "01d";
  bool _isLoading = true;

  // --- API KEY  ---
  final String _apiKey = "54172270b86276081b10277f36bff935"; 
  
  @override
  void initState() {
    super.initState();
    _timeString = _formatTime(DateTime.now());
    _dateString = _formatDate(DateTime.now());
    
    // Update waktu setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    
    // Ambil data cuaca saat aplikasi dibuka
    _fetchWeather();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Fungsi Mengupdate Waktu
  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = _formatTime(now);
    final String formattedDate = _formatDate(now);
    setState(() {
      _timeString = formattedTime;
      _dateString = formattedDate;
    });
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM yyyy').format(dateTime);
  }

  // Mengambil Data Cuaca (API)
  Future<void> _fetchWeather() async {
    // URL API OpenWeatherMap
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$_cityName&appid=$_apiKey&units=metric&lang=id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _temp = data['main']['temp'].toStringAsFixed(1); // suhu
          _description = data['weather'][0]['description']; // Deskripsi
          _iconCode = data['weather'][0]['icon']; // Icon
          _cityName = data['name'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _description = "Gagal memuat data (Cek API Key)";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _description = "Koneksi Error";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FastCycle"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- BAGIAN WAKTU ---
            const Text(
              "WAKTU SAAT INI",
              style: TextStyle(letterSpacing: 2, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              _timeString,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _dateString,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.blueAccent,
              ),
            ),
            
            const SizedBox(height: 50),
            const Divider(color: Colors.grey),
            const SizedBox(height: 50),

            // --- BAGIAN CUACA ---
            const Text(
              "CUACA TERKINI",
              style: TextStyle(letterSpacing: 2, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            _isLoading
                ? const CircularProgressIndicator()
                : Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _cityName,
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        Image.network(
                          'https://openweathermap.org/img/wn/$_iconCode@2x.png',
                          width: 80,
                        ),
                        Text(
                          "$_temp°C",
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _description.toUpperCase(),
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
            
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _fetchWeather,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Cuaca"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
            )
          ],
        ),
      ),
    );
  }
}