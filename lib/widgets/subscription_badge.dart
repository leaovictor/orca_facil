import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../core/theme/app_theme.dart';

class SubscriptionBadge extends StatelessWidget {
  final SubscriptionTier tier;
  final bool isCompact;
  final bool useLightText;

  const SubscriptionBadge({
    super.key,
    required this.tier,
    this.isCompact = false,
    this.useLightText = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPro = tier == SubscriptionTier.pro;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isPro ? AppTheme.primaryBlue : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.star : Icons.star_border,
            size: isCompact ? 12 : 16,
            color: isPro
                ? Colors.white
                : (useLightText ? Colors.white : Colors.grey[700]),
          ),
          const SizedBox(width: 4),
          Text(
            isPro ? 'PRO' : 'FREE',
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: isPro
                  ? Colors.white
                  : (useLightText ? Colors.white : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
