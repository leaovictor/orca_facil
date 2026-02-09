import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/budget/new_budget_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/services/service_form_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/subscription_screen.dart';
import '../screens/budget/budgets_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/scaffold_with_navigation.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/splash';

      // Allow splash screen
      if (isSplash) return null;

      // If not logged in and not on login/register, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login/register, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Shell Route for adaptive navigation
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsScreen(),
          ),
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Full screen routes (outside shell)
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/budget/new',
        builder: (context, state) => const NewBudgetScreen(),
      ),
      GoRoute(
        path: '/services/new',
        builder: (context, state) => const ServiceFormScreen(),
      ),
      GoRoute(
        path: '/services/edit/:id',
        builder: (context, state) {
          final serviceId = state.pathParameters['id']!;
          return ServiceFormScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );
});
