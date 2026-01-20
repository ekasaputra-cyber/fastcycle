import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_models.dart';

// --- 1. DUAL CLOCK (LAYOUT KANAN-KIRI / HORIZONTAL) ---
class DualClockWidget extends StatefulWidget {
  final int timezoneOffset;
  const DualClockWidget({super.key, required this.timezoneOffset});

  @override
  State<DualClockWidget> createState() => _DualClockWidgetState();
}

class _DualClockWidgetState extends State<DualClockWidget> {
  late Timer _timer;
  DateTime _localTime = DateTime.now();
  DateTime _destTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTimes();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimes());
  }

  void _updateTimes() {
    if (!mounted) return;
    setState(() {
      _localTime = DateTime.now();
      _destTime = DateTime.now().toUtc().add(Duration(seconds: widget.timezoneOffset));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Posisi di tengah
      crossAxisAlignment: CrossAxisAlignment.baseline, // Ratakan teks di garis dasar (bawah)
      textBaseline: TextBaseline.alphabetic,
      children: [
        // WAKTU TUJUAN (BESAR)
        Text(
          DateFormat('HH:mm').format(_destTime),
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 32, 
            fontWeight: FontWeight.bold
          ),
        ),
        const SizedBox(width: 12), // Jarak spasi antar jam
        
        // WAKTU LOKAL (KECIL)
        Text(
          "Lokal: ${DateFormat('HH:mm').format(_localTime)}",
          style: const TextStyle(
            color: Colors.white70, 
            fontSize: 14, 
            fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }
}

// --- 2. TEMPERATURE RANGE BAR ---
class TempRangeBar extends StatelessWidget {
  final double min;
  final double max;
  final double weekMin;
  final double weekMax;

  const TempRangeBar({super.key, required this.min, required this.max, required this.weekMin, required this.weekMax});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalRange = weekMax - weekMin;
          if (totalRange <= 0) return const SizedBox();
          
          final double width = constraints.maxWidth;
          final double leftPadding = ((min - weekMin) / totalRange) * width;
          final double barWidth = ((max - min) / totalRange) * width;

          return Stack(
            children: [
              Positioned(
                left: leftPadding.clamp(0.0, width),
                width: barWidth.clamp(5.0, width),
                top: 0, bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- 3. DETAIL GRID (ICON MENJADI HIJAU) ---
class DetailGrid extends StatelessWidget {
  final WeatherModel data;
  const DetailGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildItem(Icons.water_drop_outlined, "Kelembapan", "${data.humidity}%"),
        _buildItem(Icons.speed, "Tekanan", "${data.pressure} hPa"),
        _buildItem(Icons.remove_red_eye_outlined, "Visibilitas", "${(data.visibility / 1000).toStringAsFixed(1)} km"),
        _buildItem(Icons.thermostat, "Titik Embun", "${data.dewPoint.toStringAsFixed(1)}°"),
      ],
    );
  }

  Widget _buildItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1D1E22), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          // ICON DIUBAH MENJADI HIJAU (GreenAccent)
          Icon(icon, color: Colors.greenAccent, size: 28), 
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 4. MATAHARI/BULAN & AQI SECTION (DINAMIS SIANG/MALAM) ---
class SunAndAqiSection extends StatelessWidget {
  final WeatherModel data;
  const SunAndAqiSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final sunrise = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(data.sunrise * 1000).toLocal());
    final sunset = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(data.sunset * 1000).toLocal());
    
    // LOGIKA SIANG / MALAM
    // Menggunakan icon code dari API: 'd' = day, 'n' = night
    final bool isDay = data.iconCode.endsWith('d');
    
    // Tentukan Warna & Judul berdasarkan waktu
    final Color themeColor = isDay ? Colors.orange : Colors.purpleAccent;
    final String astroTitle = isDay ? "Matahari" : "Bulan";
    final IconData astroIcon = isDay ? Icons.wb_sunny : Icons.nights_stay;

    // Konfigurasi Label AQI
    String aqiLabel = ["-", "Baik", "Cukup", "Sedang", "Buruk", "Bahaya"][data.aqi.clamp(0, 5)];
    Color aqiColor = [Colors.grey, Colors.greenAccent, Colors.yellow, Colors.orange, Colors.red, Colors.purple][data.aqi.clamp(0, 5)];

    return Row(
      children: [
        // Widget Matahari / Bulan (Dinamis)
        Expanded(
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1D1E22), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(astroIcon, color: themeColor, size: 16),
                    const SizedBox(width: 5),
                    Text(astroTitle, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const Spacer(),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Kirim warna tema ke Painter
                    CustomPaint(size: const Size(double.infinity, 50), painter: AstroArcPainter(color: themeColor)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            const Text("Terbit", style: TextStyle(color: Colors.grey, fontSize: 9)),
                            Text(sunrise, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Terbenam", style: TextStyle(color: Colors.grey, fontSize: 9)),
                            Text(sunset, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Widget AQI
        Expanded(
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1D1E22), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Kualitas Udara", style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Text("AQI ${data.aqi}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                Text(aqiLabel, style: TextStyle(color: aqiColor, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: data.aqi / 5,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(aqiColor),
                    minHeight: 6,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Painter Dinamis (Bisa jadi Matahari / Bulan)
class AstroArcPainter extends CustomPainter {
  final Color color;
  AstroArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Gunakan .withValues() agar aman dari warning deprecated
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, -15, size.width, size.height);
    canvas.drawPath(path, paint);

    // Gambar lingkaran kecil (Matahari/Bulan) di tengah lengkungan
    canvas.drawCircle(Offset(size.width / 2, size.height / 2 - 5), 6, Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Repaint jika warna berubah
}