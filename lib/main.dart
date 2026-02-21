import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_types.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart'; // Import Auth
import 'viewmodels/subscription_viewmodel.dart'; // Import Subscription
import 'models/subscription_model.dart'; // Import Model
import 'routes/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Enable Firestore persistence for web
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Error enabling Firestore persistence: $e');
  }

  // Initialize locales
  await initializeDateFormatting('pt_BR', null);

  // Initialize Notifications
  final container = ProviderContainer();
  await container.read(notificationServiceProvider).init();

  runApp(
    UncontrolledProviderScope(container: container, child: const OrcaMaisApp()),
  );
}

class OrcaMaisApp extends ConsumerWidget {
  const OrcaMaisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    // Watch Subscription to determine Theme
    final user = ref.watch(authStateProvider).value;
    final subscriptionAsync = user != null
        ? ref.watch(subscriptionProvider(user.uid))
        : const AsyncValue<SubscriptionModel?>.data(null);
    final tier = subscriptionAsync.value?.tier ?? SubscriptionTier.free;

    // Map Tier to ThemeType
    AppThemeType themeType;
    switch (tier) {
      case SubscriptionTier.premium:
        themeType = AppThemeType.premium;
        break;
      case SubscriptionTier.pro:
        themeType = AppThemeType.pro;
        break;
      case SubscriptionTier.free:
        themeType = AppThemeType.free;
    }

    return MaterialApp.router(
      title: 'Orça+',
      debugShowCheckedModeBanner: false,
      // Provide Dynamic Themes
      theme: AppTheme.getTheme(type: themeType, brightness: Brightness.light),
      darkTheme: AppTheme.getTheme(
        type: themeType,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
    );
  }
}
