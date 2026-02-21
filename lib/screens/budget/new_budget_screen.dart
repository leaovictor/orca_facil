import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../models/subscription_model.dart';
import 'free_new_budget_screen.dart';
import 'pro_new_budget_screen.dart';
import 'premium_new_budget_screen.dart';

class NewBudgetScreen extends ConsumerWidget {
  const NewBudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const FreeNewBudgetScreen();

        final subscriptionAsync = ref.watch(subscriptionProvider(user.uid));

        return subscriptionAsync.when(
          data: (subscription) {
            final tier = subscription?.tier ?? SubscriptionTier.free;

            switch (tier) {
              case SubscriptionTier.premium:
                return const PremiumNewBudgetScreen();
              case SubscriptionTier.pro:
                return const ProNewBudgetScreen();
              case SubscriptionTier.free:
                return const FreeNewBudgetScreen();
            }
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const FreeNewBudgetScreen(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const FreeNewBudgetScreen(),
    );
  }
}
