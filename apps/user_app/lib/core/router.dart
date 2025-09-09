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
import '../screens/main_navigation_scaffold.dart';
import '../screens/invitations_list_screen.dart';
import '../screens/invitation_editor_screen.dart';
import '../screens/invitation_preview_screen.dart';


class AppRouter {
  static GoRouter create(UserSession session) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: session,
      // Sanitize platform-provided deep-link locations
      redirect: (ctx, state) {
        final uri = state.uri;
        // Custom scheme: saralevents://invite/:slug
        if (uri.scheme == 'saralevents' && uri.host == 'invite') {
          final slug = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
          if (slug.isNotEmpty) return '/invite/$slug';
          return '/';
        }
        // HTTPS app link: https://saralevents.vercel.app/invite/:slug
        if (uri.scheme == 'https' && uri.host == 'saralevents.vercel.app' && uri.path.startsWith('/invite/')) {
          final slug = uri.path.substring('/invite/'.length);
          if (slug.isNotEmpty) return '/invite/$slug';
          return '/';
        }
        return null;
      },
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
        GoRoute(path: '/invites', builder: (_, __) => const InvitationsListScreen()),
        GoRoute(path: '/invites/new', builder: (_, __) => const InvitationEditorScreen()),
        GoRoute(
          path: '/invites/:slug',
          builder: (ctx, st) => InvitationPreviewScreen(slug: st.pathParameters['slug']!),
        ),
        // Support app-links from web path `/invite/:slug`
        GoRoute(
          path: '/invite/:slug',
          builder: (ctx, st) => InvitationPreviewScreen(slug: st.pathParameters['slug']!),
        ),
      ],
    );
  }
}
