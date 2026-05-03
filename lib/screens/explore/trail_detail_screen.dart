import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/risk_scoring_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/risk_badge.dart';
import '../hike/log_hike_screen.dart';
import 'report_condition_screen.dart';

class TrailDetailScreen extends StatefulWidget {
  final TrailModel trail;
  const TrailDetailScreen({super.key, required this.trail});

  @override
  State<TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<TrailDetailScreen> {
  bool _refreshingRisk = false;
  RiskScoreBreakdown? _breakdown;
  late TrailModel _trail;

  @override
  void initState() {
    super.initState();
    _trail = widget.trail;
  }

  Future<void> _refreshRiskScore() async {
    setState(() => _refreshingRisk = true);
    try {
      final reports = await context.read<FirestoreService>().getRecentReports(
          _trail.id, DateTime.now().subtract(const Duration(hours: 48)));

      final breakdown = await RiskScoringService.computeAndSave(
        trail: _trail,
        recentReports: reports,
      );

      // Reload trail from Firestore to get updated score
      final updated =
          await context.read<FirestoreService>().getTrail(_trail.id);

      setState(() {
        _breakdown = breakdown;
        if (updated != null) _trail = updated;
        _refreshingRisk = false;
      });
    } catch (e) {
      setState(() => _refreshingRisk = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh risk score: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_trail.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report condition',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportConditionScreen(trail: _trail),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image / gradient header
            _TrailHeader(trail: _trail),

            // Trail metadata
            _MetadataSection(trail: _trail),

            // Risk Score Card
            _RiskScoreCard(
              trail: _trail,
              breakdown: _breakdown,
              isRefreshing: _refreshingRisk,
              onRefresh: _refreshRiskScore,
            ),

            // Community reports
            _ReportsSection(trail: _trail),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LogHikeScreen(preselectedTrail: _trail),
              ),
            ),
            icon: const Icon(Icons.hiking),
            label: const Text('Log a Hike Here'),
          ),
        ),
      ),
    );
  }
}

class _TrailHeader extends StatelessWidget {
  final TrailModel trail;
  const _TrailHeader({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryDark,
            AppTheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.terrain,
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trail.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trail.state.isNotEmpty)
                  Text(
                    '${trail.region}, ${trail.state}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  final TrailModel trail;
  const _MetadataSection({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetaTile(
                icon: Icons.straighten,
                label: 'Distance',
                value: '${trail.lengthMiles} mi',
              ),
              const SizedBox(width: 12),
              _MetaTile(
                icon: Icons.trending_up,
                label: 'Elevation',
                value: '${trail.elevationFt} ft',
              ),
              const SizedBox(width: 12),
              _MetaTile(
                icon: Icons.signal_cellular_alt,
                label: 'Difficulty',
                value: trail.difficulty,
              ),
            ],
          ),
          if (trail.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              trail.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskScoreCard extends StatelessWidget {
  final TrailModel trail;
  final RiskScoreBreakdown? breakdown;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _RiskScoreCard({
    required this.trail,
    this.breakdown,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = AppTheme.riskColorFromScore(trail.riskScore);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: riskColor, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Trail Risk Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  RiskBadge(score: trail.riskScore, level: trail.riskLevel),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isRefreshing ? null : onRefresh,
                    child: isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh,
                            color: AppTheme.textSecondary, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: trail.riskScore / 100,
              backgroundColor: riskColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${trail.riskScore}/100',
            style: TextStyle(
              fontSize: 13,
              color: riskColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Alert message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: riskColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    breakdown?.alertMessage ?? _defaultAlert(trail.riskLevel),
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // Score breakdown (shown after refresh)
          if (breakdown != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Score Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ...breakdown!.factors.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SubScore('Weather', breakdown!.weatherScore, '40%'),
                _SubScore('Community', breakdown!.communityScore, '35%'),
                _SubScore('Route', breakdown!.routeScore, '25%'),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateFormat('MMM d, h:mm a').format(trail.lastUpdated)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _defaultAlert(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return 'Conditions look favorable. Standard preparation is sufficient.';
      case 'moderate':
        return 'Exercise caution and check conditions before heading out.';
      case 'high':
        return 'High risk. Experienced hikers only with proper gear.';
      case 'extreme':
        return 'Extreme conditions. Do not attempt without professional guidance.';
      default:
        return 'Tap refresh to calculate a live risk score.';
    }
  }
}

class _SubScore extends StatelessWidget {
  final String label;
  final int score;
  final String weight;

  const _SubScore(this.label, this.score, this.weight);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.riskColorFromScore(score),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          Text(
            weight,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsSection extends StatelessWidget {
  final TrailModel trail;
  const _ReportsSection({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Community Reports',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Report'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportConditionScreen(trail: trail),
                  ),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<ReportModel>>(
          stream: context.read<FirestoreService>().getTrailReports(trail.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Text(
                  'No reports yet. Be the first to submit a trail condition.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: snapshot.data!.length,
              itemBuilder: (_, i) => _ReportCard(report: snapshot.data![i]),
            );
          },
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.conditionType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(report.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reported by ${report.userDisplayName}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
