import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/dashboard_screen.dart' as home;
import '../modules/reports/screens/reports_screen.dart';
import '../modules/reports/screens/monthly_revenue_screen.dart';
import '../modules/reports/screens/top_services_screen.dart';
import '../modules/reports/screens/recurring_clients_screen.dart';
import '../modules/reports/screens/month_comparison_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/budget/new_budget_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/services/service_form_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/subscription_screen.dart';
import '../screens/settings/plan_details_screen.dart';
import '../screens/budget/budgets_screen.dart';
import '../screens/budget/pdf_preview_screen.dart';
import '../models/budget_model.dart';
import '../models/client_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/scaffold_with_navigation.dart';
import '../screens/clients/clients_screen.dart';
import '../screens/clients/client_details_screen.dart';
import '../screens/clients/client_form_screen.dart'; // To be created next

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

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
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Shell Route for adaptive navigation
      ShellRoute(
        pageBuilder: (context, state, child) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: ScaffoldWithNavigation(child: child),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return child;
                },
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const home.DashboardScreen(),
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
            path: '/clients',
            builder: (context, state) => const ClientsScreen(),
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
      // Reports (Premium only)
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/reports/monthly-revenue',
        builder: (context, state) {
          // Import the screen at the top of the file
          return const MonthlyRevenueScreen();
        },
      ),
      GoRoute(
        path: '/reports/top-services',
        builder: (context, state) => const TopServicesScreen(),
      ),
      GoRoute(
        path: '/reports/recurring-clients',
        builder: (context, state) => const RecurringClientsScreen(),
      ),
      GoRoute(
        path: '/reports/month-comparison',
        builder: (context, state) => const MonthComparisonScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/settings/plan-details',
        builder: (context, state) => const PlanDetailsScreen(),
      ),
      GoRoute(
        path: '/budget/preview',
        builder: (context, state) {
          final budget = state.extra as BudgetModel;
          return PdfPreviewScreen(budget: budget);
        },
      ),
      GoRoute(
        path: '/clients/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/edit/:id',
        builder: (context, state) {
          final clientId = state.pathParameters['id']!;
          final client = state.extra as ClientModel?;
          return ClientFormScreen(clientId: clientId, client: client);
        },
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) {
          final clientId = state.pathParameters['id']!;
          final client = state.extra as ClientModel?;
          return ClientDetailsScreen(clientId: clientId, initialClient: client);
        },
      ),
    ],
  );
});
