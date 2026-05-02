import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/risk_badge.dart';
import '../hike/log_hike_screen.dart';
import '../explore/trail_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<List<TrailModel>>? _trailStream;
  Stream<List<HikeModel>>? _hikeStream;
  String? _uid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.userModel;
    final uid = auth.uid ?? '';

    if (uid != _uid) {
      _uid = uid;
      _trailStream = firestore.getTrails();
      _hikeStream = firestore.getUserHikes(uid);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user != null
              ? 'Welcome, ${user.displayName.split(' ').first}'
              : 'BigFoot',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LogHikeScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Log Hike'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) _StatsBanner(user: user),
              _RiskAlertSection(stream: _trailStream),
              _RecentHikesSection(stream: _hikeStream),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBanner extends StatelessWidget {
  final UserModel user;
  const _StatsBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${user.totalHikes}',
            label: 'Hikes',
            icon: Icons.hiking,
          ),
          _divider(),
          _StatItem(
            value: user.totalMiles.toStringAsFixed(1),
            label: 'Miles',
            icon: Icons.route,
          ),
          _divider(),
          _StatItem(
            value: '${user.badgesEarned.length}',
            label: 'Badges',
            icon: Icons.military_tech,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 40,
        width: 1,
        color: Colors.white.withOpacity(0.3),
      );
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RiskAlertSection extends StatelessWidget {
  final Stream<List<TrailModel>>? stream;
  const _RiskAlertSection({this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TrailModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final highRiskTrails =
            snapshot.data!.where((t) => t.riskScore > 60).take(3).toList();

        if (highRiskTrails.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.riskHigh, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Active Trail Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ...highRiskTrails.map(
              (trail) => _AlertCard(trail: trail),
            ),
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final TrailModel trail;
  const _AlertCard({required this.trail});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TrailDetailScreen(trail: trail)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.riskColorFromScore(trail.riskScore).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.riskColorFromScore(trail.riskScore).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.terrain,
              color: AppTheme.riskColorFromScore(trail.riskScore),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trail.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${trail.state} - ${trail.difficulty}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            RiskBadge(score: trail.riskScore, level: trail.riskLevel),
          ],
        ),
      ),
    );
  }
}

class _RecentHikesSection extends StatelessWidget {
  final Stream<List<HikeModel>>? stream;
  const _RecentHikesSection({this.stream});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Hikes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        StreamBuilder<List<HikeModel>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.hiking, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No hikes yet. Tap "Log Hike" to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            final hikes = snapshot.data!.take(5).toList();
            return Column(
              children: hikes.map((h) => _HikeCard(hike: h)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _HikeCard extends StatelessWidget {
  final HikeModel hike;
  const _HikeCard({required this.hike});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.hiking, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hike.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(hike.date),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${hike.distance.toStringAsFixed(1)} mi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  hike.formattedDuration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
