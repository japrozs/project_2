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

// ─── Risk Score Breakdown ─────────────────────────────────────────────────────

class RiskScoreBreakdown {
  final int weatherScore;
  final int communityScore;
  final int routeScore;
  final int totalScore;
  final String riskLevel;
  final String alertMessage;
  final List<String> factors;

  const RiskScoreBreakdown({
    required this.weatherScore,
    required this.communityScore,
    required this.routeScore,
    required this.totalScore,
    required this.riskLevel,
    required this.alertMessage,
    required this.factors,
  });
}

// ─── Risk Scoring Service ─────────────────────────────────────────────────────

class RiskScoringService {
  // Store your OpenWeatherMap API key in a .env file or Flutter --dart-define.
  // For development, replace the value below with your actual API key.
  static const String _apiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'YOUR_OPENWEATHERMAP_API_KEY',
  );

  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  // ── Public entry point ─────────────────────────────────────────────────────

  /// Computes a full risk score breakdown for a trail and persists it
  /// to Firestore, then returns the breakdown for display.
  static Future<RiskScoreBreakdown> computeAndSave({
    required TrailModel trail,
    required List<ReportModel> recentReports,
  }) async {
    // 1. Fetch live weather
    WeatherData? weather;
    try {
      weather = await _fetchWeather(
        lat: trail.location.latitude,
        lon: trail.location.longitude,
      );
    } catch (e) {
      debugPrint('Weather fetch failed: $e');
    }

    // 2. Calculate sub-scores
    final weatherScore = weather != null ? _calcWeatherScore(weather) : 50;
    final communityScore = _calcCommunityScore(recentReports);
    final routeScore = _calcRouteScore(trail);

    // 3. Weighted average: weather 40%, community 35%, route 25%
    final totalScore =
        ((weatherScore * 0.40) + (communityScore * 0.35) + (routeScore * 0.25))
            .round()
            .clamp(0, 100);

    final riskLevel = AppTheme.riskLabelFromScore(totalScore);
    final alertMessage = _buildAlertMessage(
      totalScore,
      riskLevel,
      weather,
      recentReports,
    );
    final factors = _buildFactorsList(
      weather,
      recentReports,
      trail,
      weatherScore,
      communityScore,
      routeScore,
    );

    // 4. Persist to Firestore
    await FirebaseFirestore.instance.collection('trails').doc(trail.id).update({
      'riskScore': totalScore,
      'riskLevel': riskLevel,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return RiskScoreBreakdown(
      weatherScore: weatherScore,
      communityScore: communityScore,
      routeScore: routeScore,
      totalScore: totalScore,
      riskLevel: riskLevel,
      alertMessage: alertMessage,
      factors: factors,
    );
  }

  // ── Weather fetching ───────────────────────────────────────────────────────

  static Future<WeatherData> _fetchWeather({
    required double lat,
    required double lon,
  }) async {
    final uri =
        Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Weather API returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final rain = json['rain'] as Map<String, dynamic>? ?? {};
    final weatherList = json['weather'] as List<dynamic>;

    return WeatherData(
      tempCelsius: (main['temp'] as num).toDouble(),
      windSpeedMps: (wind['speed'] as num?)?.toDouble() ?? 0,
      precipitationMm: (rain['1h'] as num?)?.toDouble() ?? 0,
      visibilityMeters: (json['visibility'] as int?) ?? 10000,
      condition:
          (weatherList.isNotEmpty ? weatherList[0]['main'] as String? : null) ??
              'Clear',
    );
  }

  // ── Sub-score calculators ─────────────────────────────────────────────────

  /// Weather score (0-100). Higher = more dangerous.
  /// Considers temperature extremes, precipitation, wind, and visibility.
  // Public wrappers exposed for unit testing
  static int calcWeatherScoreForTest(WeatherData w) => _calcWeatherScore(w);
  static int calcCommunityScoreForTest(List<ReportModel> reports) =>
      _calcCommunityScore(reports);
  static int calcRouteScoreForTest(TrailModel trail) => _calcRouteScore(trail);
  static int calcWeightedTotalForTest(int ws, int cs, int rs) =>
      ((ws * 0.40) + (cs * 0.35) + (rs * 0.25)).round().clamp(0, 100);

  static int _calcWeatherScore(WeatherData w) {
    int score = 0;

    // Temperature: dangerous if below 0°C or above 38°C
    if (w.tempCelsius < 0) {
      score += ((-w.tempCelsius / 20) * 25).round().clamp(0, 25);
    } else if (w.tempCelsius > 38) {
      score += (((w.tempCelsius - 38) / 10) * 20).round().clamp(0, 20);
    }

    // Wind: >10 m/s is concerning, >20 m/s is severe
    if (w.windSpeedMps > 10) {
      score += ((w.windSpeedMps - 10) / 20 * 30).round().clamp(0, 30);
    }

    // Precipitation: any rain raises risk
    if (w.precipitationMm > 0) {
      score += (w.precipitationMm / 10 * 25).round().clamp(0, 25);
    }

    // Visibility: poor visibility below 1km
    if (w.visibilityMeters < 1000) {
      score += ((1000 - w.visibilityMeters) / 1000 * 20).round().clamp(0, 20);
    }

    // Condition bonus
    switch (w.condition.toLowerCase()) {
      case 'thunderstorm':
        score += 25;
        break;
      case 'snow':
        score += 20;
        break;
      case 'rain':
      case 'drizzle':
        score += 10;
        break;
      case 'fog':
      case 'mist':
        score += 8;
        break;
    }

    return score.clamp(0, 100);
  }

  /// Community score (0-100) based on recent user reports.
  /// Reports in last 24 hrs are weighted at 1.5x, 24-48 hrs at 1.0x.
  static int _calcCommunityScore(List<ReportModel> reports) {
    if (reports.isEmpty) return 0;

    final now = DateTime.now();
    final conditionWeights = {
      'Washed Out': 90,
      'Flooded': 85,
      'Trail Closed': 95,
      'Ice / Snow': 75,
      'Fallen Tree': 50,
      'Poor Visibility': 60,
      'High Wind': 65,
      'Muddy': 35,
      'Overgrown': 20,
      'Excellent': -20,
      'Good': -10,
    };

    double totalWeight = 0;
    double totalScore = 0;

    for (final report in reports) {
      final ageHours = now.difference(report.timestamp).inHours;
      final recencyWeight = ageHours <= 24 ? 1.5 : 1.0;
      final conditionScore =
          conditionWeights[report.conditionType]?.toDouble() ?? 40;
      totalScore += conditionScore * recencyWeight;
      totalWeight += recencyWeight;
    }

    if (totalWeight == 0) return 0;
    return (totalScore / totalWeight).round().clamp(0, 100);
  }

  /// Route metadata score (0-100) based on static trail attributes.
  static int _calcRouteScore(TrailModel trail) {
    int score = 0;

    // Difficulty
    switch (trail.difficulty.toLowerCase()) {
      case 'easy':
        score += 10;
        break;
      case 'moderate':
        score += 25;
        break;
      case 'hard':
        score += 45;
        break;
      case 'expert':
        score += 65;
        break;
    }

    // Elevation gain
    if (trail.elevationFt > 2000)
      score += 20;
    else if (trail.elevationFt > 1000)
      score += 10;
    else if (trail.elevationFt > 500) score += 5;

    // Length
    if (trail.lengthMiles > 15)
      score += 15;
    else if (trail.lengthMiles > 8)
      score += 8;
    else if (trail.lengthMiles > 4) score += 4;

    return score.clamp(0, 100);
  }

  // ── Alert message builder ──────────────────────────────────────────────────

  static String _buildAlertMessage(
    int score,
    String level,
    WeatherData? weather,
    List<ReportModel> reports,
  ) {
    if (score <= 30) {
      return 'Conditions look favorable for this trail. Standard preparation is sufficient.';
    } else if (score <= 60) {
      final parts = <String>[];
      if (weather != null) {
        if (weather.windSpeedMps > 10) parts.add('elevated wind speed');
        if (weather.precipitationMm > 0) parts.add('precipitation');
      }
      if (reports.isNotEmpty) parts.add('recent trail reports');
      final detail = parts.isNotEmpty ? ' due to ${parts.join(', ')}' : '';
      return 'Exercise caution$detail. Check conditions before heading out and inform someone of your plans.';
    } else if (score <= 80) {
      return 'High risk conditions detected. This trail requires experienced hikers with proper gear. Consider postponing.';
    } else {
      return 'Extreme risk. Current conditions make this trail hazardous. Do not attempt without professional guidance.';
    }
  }

  /// Produces human-readable factor descriptions for the UI breakdown panel.
  static List<String> _buildFactorsList(
    WeatherData? weather,
    List<ReportModel> reports,
    TrailModel trail,
    int ws,
    int cs,
    int rs,
  ) {
    final factors = <String>[];

    // Weather factors
    if (weather != null) {
      factors.add('Weather (${ws}pts): ${weather.condition}, '
          '${weather.tempCelsius.round()}°C, '
          'wind ${weather.windSpeedMps.round()} m/s');
    } else {
      factors.add('Weather ($ws pts): data unavailable - default applied');
    }

    // Community factors
    if (reports.isEmpty) {
      factors.add('Community ($cs pts): no reports in the past 48 hours');
    } else {
      final last = reports.first;
      factors.add('Community ($cs pts): ${reports.length} recent report(s), '
          'latest - ${last.conditionType}');
    }

    // Route factors
    factors.add('Route ($rs pts): ${trail.difficulty} difficulty, '
        '${trail.lengthMiles} mi, ${trail.elevationFt} ft gain');

    return factors;
  }
}
