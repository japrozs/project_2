import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/risk_badge.dart';
import 'trail_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedDifficulty = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late Stream<List<TrailModel>> _trailStream;

  static const _difficulties = ['All', 'Easy', 'Moderate', 'Hard', 'Expert'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trailStream = context
        .read<FirestoreService>()
        .getTrails(difficulty: _selectedDifficulty);
  }

  void _setDifficulty(String d) {
    setState(() {
      _selectedDifficulty = d;
      _trailStream = context.read<FirestoreService>().getTrails(difficulty: d);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Trails'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search trails...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Difficulty filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: _difficulties.map((d) {
                final selected = _selectedDifficulty == d;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(d),
                    selected: selected,
                    onSelected: (_) => _setDifficulty(d),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primary.withOpacity(0.15),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected ? AppTheme.primary : AppTheme.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Trail list
          Expanded(
            child: StreamBuilder<List<TrailModel>>(
              stream: _trailStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terrain,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No trails found',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                var trails = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  trails = trails
                      .where((t) =>
                          t.name.toLowerCase().contains(q) ||
                          t.state.toLowerCase().contains(q) ||
                          t.region.toLowerCase().contains(q))
                      .toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: trails.length,
                  itemBuilder: (context, i) => _TrailCard(trail: trails[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailCard extends StatelessWidget {
  final TrailModel trail;
  const _TrailCard({required this.trail});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TrailDetailScreen(trail: trail),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trail.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trail.state.isNotEmpty
                              ? '${trail.region} - ${trail.state}'
                              : trail.region,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RiskBadge(score: trail.riskScore, level: trail.riskLevel),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.straighten,
                    label: '${trail.lengthMiles} mi',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.trending_up,
                    label: '${trail.elevationFt} ft',
                  ),
                  const SizedBox(width: 8),
                  _DifficultyChip(difficulty: trail.difficulty),
                ],
              ),
              if (trail.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  trail.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String difficulty;
  const _DifficultyChip({required this.difficulty});

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.riskLow;
      case 'moderate':
        return AppTheme.riskModerate;
      case 'hard':
        return AppTheme.riskHigh;
      case 'expert':
        return AppTheme.riskExtreme;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 12,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
