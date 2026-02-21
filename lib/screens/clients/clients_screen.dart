import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../models/subscription_model.dart';
import 'free_clients_screen.dart';
import 'pro_clients_screen.dart';
import 'premium_clients_screen.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const FreeClientsScreen();

        final subscriptionAsync = ref.watch(subscriptionProvider(user.uid));

        return subscriptionAsync.when(
          data: (subscription) {
            final tier = subscription?.tier ?? SubscriptionTier.free;

            switch (tier) {
              case SubscriptionTier.premium:
                return const PremiumClientsScreen();
              case SubscriptionTier.pro:
                return const ProClientsScreen();
              case SubscriptionTier.free:
                return const FreeClientsScreen();
            }
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const FreeClientsScreen(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const FreeClientsScreen(),
    );
  }
}
