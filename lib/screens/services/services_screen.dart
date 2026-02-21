import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../models/subscription_model.dart';
import 'free_services_screen.dart';
import 'pro_services_screen.dart';
import 'premium_services_screen.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const FreeServicesScreen();

        final subscriptionAsync = ref.watch(subscriptionProvider(user.uid));

        return subscriptionAsync.when(
          data: (subscription) {
            final tier = subscription?.tier ?? SubscriptionTier.free;

            switch (tier) {
              case SubscriptionTier.premium:
                return const PremiumServicesScreen();
              case SubscriptionTier.pro:
                return const ProServicesScreen();
              case SubscriptionTier.free:
                return const FreeServicesScreen();
            }
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const FreeServicesScreen(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const FreeServicesScreen(),
    );
  }
}
