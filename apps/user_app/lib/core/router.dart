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
import '../screens/account_setup_screen.dart';
import '../screens/debug_screen.dart';
import '../screens/main_navigation_scaffold.dart';
import '../screens/invitations_list_screen.dart';
import '../screens/invitation_editor_screen.dart';
import '../screens/invitation_preview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/select_location_screen.dart';
import '../screens/map_location_picker.dart';
import '../screens/all_categories_screen.dart';
import '../screens/all_events_screen.dart';


class AppRouter {
  static GoRouter create(UserSession session) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: session,
      // Sanitize platform-provided deep-link locations
      redirect: (ctx, state) {
        final uri = state.uri;
        // Handle auth email confirmation deep link: saralevents://auth/confirm
        if (uri.scheme == 'saralevents' && uri.host == 'auth' && uri.path.startsWith('/confirm')) {
          final s = Provider.of<UserSession>(ctx, listen: false);
          // If already logged in, proceed to setup (profile completion). Otherwise go to login.
          return s.isAuthenticated ? '/auth/setup' : '/auth/login?verified=1';
        }
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
            // If authenticated, check setup then location
            if (s.isAuthenticated) {
              if (!s.isProfileSetupComplete) return '/auth/setup';
              return '/location/check';
            }
            // Only show onboarding for unauthenticated users who haven't completed it
            if (!s.isOnboardingComplete) return '/onboarding';
            return '/auth/pre';
          },
          builder: (ctx, st) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/location/check',
          redirect: (ctx, st) async {
            final prefs = await SharedPreferences.getInstance();
            final has = prefs.containsKey('loc_lat') && prefs.containsKey('loc_lng');
            return has ? '/app' : '/location/select';
          },
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/location/select',
          builder: (_, __) => const SelectLocationScreen(),
        ),
        GoRoute(
          path: '/location/map',
          builder: (_, __) => const MapLocationPicker(),
        ),
        GoRoute(
          path: '/onboarding',
          redirect: (ctx, state) {
            final s = Provider.of<UserSession>(ctx, listen: false);
            if (s.isPasswordRecovery) return '/auth/reset';
            // If onboarding already completed, go to pre-auth
            if (s.isOnboardingComplete) return '/auth/pre';
            // Authenticated users should go to app
            if (s.isAuthenticated) return '/app';
            return null;
          },
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/auth/pre',
          builder: (_, __) => const PreAuthScreen(),
        ),
        GoRoute(
          path: '/auth/setup',
          builder: (_, __) => const AccountSetupScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          redirect: (ctx, state) {
            final s = Provider.of<UserSession>(ctx, listen: false);
            if (s.isPasswordRecovery) return '/auth/reset';
            return null;
          },
          builder: (_, st) => LoginScreen(
            showVerifiedPrompt: st.uri.queryParameters['verified'] == '1' ||
                st.uri.queryParameters['from'] == 'verify',
          ),
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
        GoRoute(
          path: '/categories',
          builder: (_, __) => const AllCategoriesScreen(),
        ),
        GoRoute(
          path: '/events',
          builder: (_, __) => const AllEventsScreen(),
        ),
      ],
    );
  }
}
