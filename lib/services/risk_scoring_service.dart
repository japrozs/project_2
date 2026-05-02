import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

// ─── Weather Data Model ───────────────────────────────────────────────────────

class WeatherData {
  final double tempCelsius;
  final double windSpeedMps;
  final double precipitationMm;
  final int visibilityMeters;
  final String condition;

  const WeatherData({
    required this.tempCelsius,
    required this.windSpeedMps,
    required this.precipitationMm,
    required this.visibilityMeters,
    required this.condition,
  });
}
