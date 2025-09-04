import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'session.dart';
import '../screens/onboarding_screen.dart';
import '../screens/pre_auth_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/role_mismatch_screen.dart';
import '../screens/debug_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/main_navigation_scaffold.dart';


class AppRouter {
  static GoRouter create(UserSession session) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: session,
      routes: [
        GoRoute(
          path: '/',
          redirect: (ctx, state) {
            final s = Provider.of<UserSession>(ctx, listen: false);
            if (s.isPasswordRecovery) return '/auth/reset';
            if (!s.isOnboardingComplete) return '/onboarding';
            if (!s.isAuthenticated) return '/auth/pre';
            return '/app';
          },
          builder: (ctx, st) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/onboarding',
          redirect: (ctx, state) {
            final s = Provider.of<UserSession>(ctx, listen: false);
            if (s.isPasswordRecovery) return '/auth/reset';
            return null;
          },
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/auth/pre',
          builder: (_, __) => const PreAuthScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          redirect: (ctx, state) {
            final s = Provider.of<UserSession>(ctx, listen: false);
            if (s.isPasswordRecovery) return '/auth/reset';
            return null;
          },
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          redirect: (ctx, state) {
            final s = Provider.of<UserSession>(ctx, listen: false);
            if (s.isPasswordRecovery) return '/auth/reset';
            return null;
          },
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(path: '/auth/forgot', builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/auth/reset', builder: (_, __) => const ResetPasswordScreen()),
        GoRoute(path: '/auth/role-mismatch', builder: (_, __) => const RoleMismatchScreen()),
        GoRoute(path: '/debug', builder: (_, __) => const DebugScreen()),
        GoRoute(path: '/app', builder: (_, __) => const MainNavigationScaffold()),
      ],
    );
  }
}
