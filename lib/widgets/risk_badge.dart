import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RiskBadge extends StatelessWidget {
  final int score;
  final String level;
  final bool compact;

  const RiskBadge({
    super.key,
    required this.score,
    required this.level,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.riskColor(level);

    if (compact) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
