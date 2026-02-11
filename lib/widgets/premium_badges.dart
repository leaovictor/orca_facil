import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Badge Component
///
/// Badges pequenos para status, planos, etc
class Badge extends StatelessWidget {
  final String text;
  final BadgeType type;
  final bool small;

  const Badge({
    super.key,
    required this.text,
    this.type = BadgeType.neutral,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(type);

    return Container(
      height: small ? 20 : 24,
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: 0),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: small ? 10 : 12,
            fontWeight: FontWeight.w600,
            color: colors.text,
            height: 1,
          ),
        ),
      ),
    );
  }

  _BadgeColors _getColors(BadgeType type) {
    switch (type) {
      case BadgeType.pro:
        return const _BadgeColors(
          background: AppTheme.primaryBlue,
          text: Colors.white,
        );
      case BadgeType.free:
        return const _BadgeColors(
          background: AppTheme.slate200,
          text: AppTheme.textSecondary,
        );
      case BadgeType.success:
        return const _BadgeColors(
          background: AppTheme.successGreen,
          text: Colors.white,
        );
      case BadgeType.warning:
        return const _BadgeColors(
          background: AppTheme.warningColor,
          text: Colors.white,
        );
      case BadgeType.error:
        return const _BadgeColors(
          background: AppTheme.errorColor,
          text: Colors.white,
        );
      case BadgeType.neutral:
        return const _BadgeColors(
          background: AppTheme.slate200,
          text: AppTheme.textPrimary,
        );
    }
  }
}

enum BadgeType { pro, free, success, warning, error, neutral }

class _BadgeColors {
  final Color background;
  final Color text;

  const _BadgeColors({required this.background, required this.text});
}

/// Premium Badge with Icon
///
/// Badge com ícone, usado para planos PRO/FREE
class PlanBadge extends StatelessWidget {
  final bool isPro;
  final bool compact;

  const PlanBadge({super.key, this.isPro = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: isPro ? AppTheme.primaryBlue : AppTheme.slate200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.star : Icons.star_border,
            size: compact ? 12 : 14,
            color: isPro ? Colors.white : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isPro ? 'PRO' : 'FREE',
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: isPro ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
