import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../core/theme/app_theme.dart';

class SubscriptionBadge extends StatelessWidget {
  final SubscriptionTier tier;

  const SubscriptionBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final isPro = tier == SubscriptionTier.pro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPro ? AppTheme.secondaryGreen : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.star : Icons.star_border,
            size: 16,
            color: isPro ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(
            isPro ? 'PRO' : 'FREE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPro ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
