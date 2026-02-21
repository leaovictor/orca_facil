import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../models/subscription_model.dart';
import '../../modules/dashboard/screens/free_dashboard_screen.dart';
import '../../modules/dashboard/screens/pro_dashboard_screen.dart';
import '../../modules/dashboard/screens/premium_dashboard_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const FreeDashboardScreen();

        // Watch subscription to decide which dashboard to show
        final subscriptionAsync = ref.watch(subscriptionProvider(user.uid));

        return subscriptionAsync.when(
          data: (subscription) {
            final tier = subscription?.tier ?? SubscriptionTier.free;

            switch (tier) {
              case SubscriptionTier.premium:
                return const PremiumDashboardScreen();
              case SubscriptionTier.pro:
                return const ProDashboardScreen();
              case SubscriptionTier.free:
                return const FreeDashboardScreen();
            }
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const FreeDashboardScreen(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const FreeDashboardScreen(),
    );
  }
}
