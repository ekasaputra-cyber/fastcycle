// lib/widgets/live_clock.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  String _timeString = "";
  String _dateString = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    // Cek mounted agar tidak error saat widget didispose
    if (mounted) {
      setState(() {
        _timeString = DateFormat('HH:mm:ss').format(now);
        _dateString = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now); // Pastikan locale ID
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "WAKTU SAAT INI",
          style: TextStyle(letterSpacing: 2, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          _timeString.isEmpty ? "--:--:--" : _timeString,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        Text(
          _dateString,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.blueAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}