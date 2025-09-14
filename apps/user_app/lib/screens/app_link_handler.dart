import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class AppLinkHandler extends StatefulWidget {
  final Widget child;

  const AppLinkHandler({super.key, required this.child});

  @override
  State<AppLinkHandler> createState() => _AppLinkHandlerState();
}

class _AppLinkHandlerState extends State<AppLinkHandler> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    
    // Listen to incoming app links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Received app link: $uri');
        _handleAppLink(uri.toString());
      },
      onError: (err) {
        print('🔗 App link error: $err');
      },
    );

    // Check for initial link (when app is opened from a link)
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        print('🔗 Initial app link: $uri');
        _handleAppLink(uri.toString());
      }
    });
  }

  void _handleAppLink(String link) {
    print('🔗 Handling app link: $link');
    final uri = Uri.parse(link);
    print('🔗 Parsed URI: scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}');
    
    // Email confirmation: saralevents://auth/confirm or https://<site>/auth/confirm
    if ((uri.scheme == 'saralevents' && uri.host == 'auth' && uri.path.startsWith('/confirm')) ||
        (uri.scheme == 'https' && uri.path.startsWith('/auth/confirm'))) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          context.go('/auth/setup');
        }
      });
      return;
    }

    // Handle custom scheme: saralevents://invite/{slug}
    if (uri.scheme == 'saralevents' && uri.host == 'invite') {
      // For saralevents://invite/abc-2865, the path is "/abc-2865"
      final slug = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      print('🔗 Custom scheme slug: $slug');
      if (slug.isNotEmpty) {
        // Add a small delay to ensure the app is fully initialized
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            print('🔗 Navigating to: /invite/$slug');
            context.go('/invite/$slug');
          }
        });
      }
      return;
    }
    
    // Handle HTTPS scheme: https://saralevents.vercel.app/invite/{slug}
    if (uri.scheme == 'https' && uri.host == 'saralevents.vercel.app' && uri.path.startsWith('/invite/')) {
      final slug = uri.path.substring('/invite/'.length);
      print('🔗 HTTPS scheme slug: $slug');
      if (slug.isNotEmpty) {
        // Add a small delay to ensure the app is fully initialized
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            print('🔗 Navigating to: /invite/$slug');
            context.go('/invite/$slug');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}