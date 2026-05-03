import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  final UserModel user;
  const AchievementsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final earned = user.badgesEarned;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppTheme.primary.withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.military_tech,
                    color: AppTheme.primary, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${earned.length} of ${AppBadges.all.length} Badges Earned',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Keep hiking to unlock more!',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: AppBadges.all.length,
              itemBuilder: (_, i) {
                final badge = AppBadges.all[i];
                final isEarned = earned.contains(badge.id);
                return _BadgeTile(badge: badge, isEarned: isEarned);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isEarned;

  const _BadgeTile({required this.badge, required this.isEarned});

  IconData get _icon {
    switch (badge.icon) {
      case 'boot':
        return Icons.directions_walk;
      case 'trail':
        return Icons.route;
      case 'mountain':
        return Icons.terrain;
      case 'fire':
        return Icons.local_fire_department;
      case 'flag':
        return Icons.flag;
      case 'road':
        return Icons.straighten;
      case 'map':
        return Icons.map;
      case 'trophy':
        return Icons.emoji_events;
      case 'people':
        return Icons.people;
      case 'camera':
        return Icons.camera_alt;
      default:
        return Icons.military_tech;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEarned ? AppTheme.primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isEarned ? AppTheme.primary.withOpacity(0.3) : AppTheme.divider,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isEarned
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon,
              color: isEarned ? AppTheme.primary : Colors.grey.shade400,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isEarned ? AppTheme.textPrimary : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isEarned ? AppTheme.textSecondary : Colors.grey.shade300,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
