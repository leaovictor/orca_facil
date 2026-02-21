import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../models/subscription_model.dart';
import 'free_settings_screen.dart';
import 'pro_settings_screen.dart';
import 'premium_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const FreeSettingsScreen();

        final subscriptionAsync = ref.watch(subscriptionProvider(user.uid));

        return subscriptionAsync.when(
          data: (subscription) {
            final tier = subscription?.tier ?? SubscriptionTier.free;

            switch (tier) {
              case SubscriptionTier.premium:
                return const PremiumSettingsScreen();
              case SubscriptionTier.pro:
                return const ProSettingsScreen();
              case SubscriptionTier.free:
                return const FreeSettingsScreen();
            }
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const FreeSettingsScreen(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const FreeSettingsScreen(),
    );
  }
}
